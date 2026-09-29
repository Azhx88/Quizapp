import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzapp/network/message_models.dart';
import 'package:quizzapp/network/network_service.dart';
import 'package:quizzapp/network/nsd_helper.dart';

final networkServiceProvider = Provider<NetworkService>((ref) {
  ref.onDispose(() => NetworkService.instance.dispose());
  return NetworkService.instance;
});

final nsdHelperProvider = Provider<NsdHelper>((ref) {
  ref.onDispose(() => NsdHelper.instance.stopAll());
  return NsdHelper.instance;
});

final networkMessagesProvider = StreamProvider<NetworkMessage>((ref) {
  return ref.watch(networkServiceProvider).messages;
});

final connectionEventsProvider = StreamProvider<String>((ref) {
  return ref.watch(networkServiceProvider).connectionEvents;
});

final discoveredHostsProvider = StreamProvider<List<DiscoveredHost>>((ref) {
  return ref.watch(nsdHelperProvider).discoveredHosts;
});

// Player count updated from connection events
final playerCountProvider = StateProvider<int>((ref) => 0);

final localIpProvider = FutureProvider<String?>((ref) {
  return NsdHelper.instance.getLocalIpAddress();
});
