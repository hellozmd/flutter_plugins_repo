# flutter_plugins_repo
# More detail usage, see https://dart.dev/tools/pub/dependencies
-Common Usage:
1. Add an plugin to repo: Copy plugin project into packages
2. Using plugin which is config in git repository - Adding dependency in your project's pubspec.yaml:
(```)
dependencies:
    plugin_name:
        git:
          url: http://10.222.151.150:10080/root/flutter-pub.git
          path: packages/your_plugin_folder
          [ref: some-branch]
(```)