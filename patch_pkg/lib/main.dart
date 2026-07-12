@pragma('dyn-module:can-be-overridden')
@pragma('vm:entry-point')
@pragma('vm:never-inline')
String rippleBuildTag() => 'v2-PATCHED';

@pragma('dyn-module:entry-point')
void dynamicModuleEntrypoint() => rippleBuildTag();
