package sk.fourq.otaupdate;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import java.io.File;
import java.util.Arrays;
import java.util.Date;
import java.util.Map;

/**
 * OtaUpdatePlugin
 */
@TargetApi(Build.VERSION_CODES.M)
public class OtaUpdatePlugin implements EventChannel.StreamHandler, PluginRegistry.RequestPermissionsResultListener {

    private static final String BYTES_DOWNLOADED = "BYTES_DOWNLOADED";
    private static final String BYTES_TOTAL = "BYTES_TOTAL";
    private static final String ERROR = "ERROR";
    public static final String ARG_URL = "url";
    public static final String ARG_FILENAME = "filename";
    public static final String ARG_ANDROID_PROVIDER_AUTHORITY = "androidProviderAuthority";
    public static final long MAX_WAIT_FOR_DOWNLOAD_START = 5000; //5s

    enum OtaStatus {
        DOWNLOADING, INSTALLING, ALREADY_RUNNING_ERROR, PERMISSION_NOT_GRANTED_ERROR, INTERNAL_ERROR, DOWNLOAD_ERROR
    }

    private final Registrar registrar;
    private EventChannel.EventSink progressSink;
    private String downloadUrl;
    private String filename;
    private String androidProviderAuthority = "sk.fourq.ota_update.provider"; //FALLBACK provider authority
    private static final String TAG = "FLUTTER OTA";
    private Handler handler;
    private Context context;

    private OtaUpdatePlugin(Registrar registrar) {
        this.registrar = registrar;
        context = (registrar.activity() != null) ? registrar.activity() : registrar.context();
        handler = new Handler(context.getMainLooper()) {
            @Override
            public void handleMessage(Message msg) {
                super.handleMessage(msg);
                if (progressSink != null) {
                    Bundle data = msg.getData();
                    if (data.containsKey(ERROR)) {
                        reportError(OtaStatus.DOWNLOAD_ERROR, data.getString(ERROR));
                    } else {
                        long bytesDownloaded = data.getLong(BYTES_DOWNLOADED);
                        long bytesTotal = data.getLong(BYTES_TOTAL);
                        progressSink.success(Arrays.asList("" + OtaStatus.DOWNLOADING.ordinal(), "" + ((bytesDownloaded * 100) / bytesTotal)));
                    }
                }
            }
        };
    }

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        OtaUpdatePlugin plugin = new OtaUpdatePlugin(registrar);
        final EventChannel progressChannel = new EventChannel(registrar.messenger(), "sk.fourq.ota_update");
        progressChannel.setStreamHandler(plugin);
        registrar.addRequestPermissionsResultListener(plugin);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        if (progressSink != null) {
            progressSink.error("" + OtaStatus.ALREADY_RUNNING_ERROR.ordinal(), "Method call was cancelled. One method call is already running", null);
        }
        Log.d(TAG, "OTA UPDATE ON LISTEN");
        progressSink = events;
        Map argumentsMap = ((Map) arguments);
        downloadUrl = argumentsMap.get(ARG_URL).toString();
        if (argumentsMap.containsKey(ARG_FILENAME)) {
            filename = argumentsMap.get(ARG_FILENAME).toString();
        }

        // user-provided provider authority
        Object authority = ((Map) arguments).get(ARG_ANDROID_PROVIDER_AUTHORITY);
        if (authority != null) {
            androidProviderAuthority = authority.toString();
        } else {
            androidProviderAuthority = context.getPackageName() + "." + "fileProvider";
        }

        if (
//                PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(registrar.context(), Manifest.permission.ACCESS_WIFI_STATE) &&
//                PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(registrar.context(), Manifest.permission.ACCESS_NETWORK_STATE) &&
                PackageManager.PERMISSION_GRANTED == ContextCompat.checkSelfPermission(registrar.context(), Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
            handleCall();
        } else {
            String[] permissions = {
//                    Manifest.permission.ACCESS_WIFI_STATE,
//                    Manifest.permission.ACCESS_NETWORK_STATE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
            };
            ActivityCompat.requestPermissions(registrar.activity(), permissions, 0);
        }
    }

    @Override
    public void onCancel(Object o) {
        progressSink = null;
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] strings, int[] grantResults) {
        if (requestCode == 0 && grantResults.length > 0) {
            for (int grantResult : grantResults) {
                if (grantResult != PackageManager.PERMISSION_GRANTED) {
                    progressSink.error("" + OtaStatus.PERMISSION_NOT_GRANTED_ERROR.ordinal(), null, null);
                    progressSink = null;
                    return false;
                }
            }
            handleCall();
            return true;
        } else {
            if (progressSink != null) {
                progressSink.error("" + OtaStatus.PERMISSION_NOT_GRANTED_ERROR.ordinal(), null, null);
                progressSink = null;
            }
            return false;
        }
    }

    private void handleCall() {
        try {
            //PREPARE URLS
            if (filename == null) {
                filename = "mbc_app_" + new Date() +  ".apk";
            }
            final String destination = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS).getAbsolutePath() + "/" + filename;
            final Uri fileUri = Uri.parse("file://" + destination);

            //DELETE APK FILE IF SOME ALREADY EXISTS
            File file = new File(destination);
            if (file.exists()) {
                if (!file.delete()) {
                    Log.e(TAG, "ERROR: unable to delete old apk file before starting OTA");
                }
            }

            Log.d(TAG, "OTA UPDATE ON STARTING DOWNLOAD");
            //CREATE DOWNLOAD MANAGER REQUEST
            DownloadManager.Request request = new DownloadManager.Request(Uri.parse(downloadUrl));
            request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE);
            request.setDestinationUri(fileUri);

            //GET DOWNLOAD SERVICE AND ENQUEUE OUR DOWNLOAD REQUEST
            final DownloadManager manager = (DownloadManager) context.getSystemService(Context.DOWNLOAD_SERVICE);
            final long downloadId = manager.enqueue(request);

            Log.d(TAG, "OTA UPDATE DOWNLOAD STARTED " + downloadId);
            //START TRACKING DOWNLOAD PROGRESS IN SEPARATE THREAD
            trackDownloadProgress(downloadId, manager);

            //REGISTER LISTENER TO KNOW WHEN DOWNLOAD IS COMPLETE
            context.registerReceiver(new BroadcastReceiver() {
                public void onReceive(Context c, Intent i) {
                    //DOWNLOAD IS COMPLETE, UNREGISTER RECEIVER AND CLOSE PROGRESS SINK
                    context.unregisterReceiver(this);
                    //SEND INSTALLING EVENT
                    if (progressSink != null) {
                        //NOTE: We have to start intent before sending event to stream
                        //if application tries to programatically terminate app it may produce race condition
                        //and application may end before intent is dispatched
//                        context.startActivity(intent);
                        progressSink.success(Arrays.asList("" + OtaStatus.INSTALLING.ordinal(), "" + destination));
                        progressSink.endOfStream();
                        progressSink = null;
                    }
                }
            }, new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));
        } catch (Exception e) {
            if (progressSink != null) {
                progressSink.error("" + OtaStatus.INTERNAL_ERROR.ordinal(), e.getMessage(), null);
                progressSink = null;
            }
            Log.e(TAG, "ERROR: " + e.getMessage(), e);
        }
    }

    private void trackDownloadProgress(final long downloadId, final DownloadManager manager) {
        Log.d(TAG, "OTA UPDATE TRACK DOWNLOAD STARTED " + downloadId);
        new Thread(new Runnable() {
            @Override
            public void run() {
                Log.d(TAG, "OTA UPDATE TRACK DOWNLOAD THREAD STARTED " + downloadId);
                //REPORT PROGRESS WHILE DOWNLOAD STILL RUNS
                boolean downloading = true;
                boolean hasStatus = false;
                long downloadStart = System.currentTimeMillis();
                while (downloading) {
                    //QUERY CURRENT PROGRESS STATUS
                    DownloadManager.Query q = new DownloadManager.Query();
                    q.setFilterById(downloadId);
                    Cursor c = manager.query(q);
                    if (c.moveToFirst()) {
                        hasStatus = true;
                        //PUSH THE STATUS THROUGH THE SINK
//                        long bytes_downloaded = c.getLong(c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
//                        long bytes_total = c.getLong(c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));
//                        if (progressSink != null && bytes_total > 0) {
//                            Message message = new Message();
//                            Bundle data = new Bundle();
//                            data.putLong(BYTES_DOWNLOADED, bytes_downloaded);
//                            data.putLong(BYTES_TOTAL, bytes_total);
//                            message.setData(data);
//                            handler.sendMessage(message);
//                        }
                        //STOP CYCLE IF DOWNLOAD IS COMPLETE
                        int status = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_STATUS));

                        if (status == DownloadManager.STATUS_SUCCESSFUL) { //success
                            Log.d(TAG, "OTA UPDATE SUCCESS");
                            downloading = false;
                        } else if (status == DownloadManager.STATUS_PENDING) { //running
                            Log.d(TAG, "OTA UPDATE PENDING");
                        } else if (status == DownloadManager.STATUS_RUNNING) { //running
                            Log.d(TAG, "OTA UPDATE TRACK DOWNLOAD RUNNING ");
                        } else if (status == DownloadManager.STATUS_FAILED) { //failed
                            downloading = false;
                            Log.d(TAG, "OTA UPDATE FAILURE: " + c.getInt(c.getColumnIndex(DownloadManager.COLUMN_REASON)));
                            Message message = new Message();
                            Bundle data = new Bundle();
                            data.putString(ERROR, "RECEIVED STATUS FAILED");
                            message.setData(data);
                            handler.sendMessage(message);
                        } else if (status == DownloadManager.STATUS_PAUSED) { //failed, but may be retryied on device restart
                            Log.d(TAG, "OTA UPDATE PAUSED. REASON IS (CHECK AGAINST PAUSED_ CONSTANTS OF DownloadManager: " + c.getInt(c.getColumnIndex(DownloadManager.COLUMN_REASON)));
                        }

                        //CLOSE CURSOR
                        c.close();
                        //WAIT FOR 1/4 SECOND FOR ANOTHER ITERATION
                        try {
                            Thread.sleep(500);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    } else {
                        long duration = System.currentTimeMillis() - downloadStart;
                        if (!hasStatus && duration > MAX_WAIT_FOR_DOWNLOAD_START) {
                            //NOTE: If no status could be obtained from download manager for 5s after starting
                            // the download something is bad and we will throw error.
                            downloading = false;
                            Log.d(TAG, "OTA UPDATE FAILURE: DOWNLOAD DID NOT START AFTER 5000ms");
                            Message message = new Message();
                            Bundle data = new Bundle();
                            data.putString(ERROR, "DOWNLOAD DID NOT START AFTER 5000ms");
                            message.setData(data);
                            handler.sendMessage(message);
                        }
                    }
                }
            }
        }).start();
    }

    private void reportError(OtaStatus internalError, String s) {
        if (progressSink != null) {
            progressSink.error("" + internalError.ordinal(), s, null);
            progressSink = null;
        }
    }
}
