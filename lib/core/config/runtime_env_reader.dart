import 'runtime_env_reader_stub.dart'
    if (dart.library.html) 'runtime_env_reader_web.dart';

String? readRuntimeEnv(String key) {
  return readRuntimeEnvImpl(key);
}
