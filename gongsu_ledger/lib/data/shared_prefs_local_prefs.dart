import 'package:shared_preferences/shared_preferences.dart';

import 'local_prefs.dart';

/// shared_preferences 구현. main()에서 1회 로드해 주입한다.
class SharedPrefsLocalPrefs implements LocalPrefs {
  SharedPrefsLocalPrefs(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
}
