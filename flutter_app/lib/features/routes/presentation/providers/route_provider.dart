import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/route_model.dart';
import '../../data/repositories/route_repository.dart';

class RouteState {
  final List<RouteModel> routes;
  final bool isLoading;
  final String? error;

  RouteState({
    this.routes = const [],
    this.isLoading = false,
    this.error,
  });

  RouteState copyWith({
    List<RouteModel>? routes,
    bool? isLoading,
    String? error,
  }) {
    return RouteState(
      routes: routes ?? this.routes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  final repository = ref.read(routeRepositoryProvider);
  return RouteNotifier(repository);
});

class RouteNotifier extends StateNotifier<RouteState> {
  final RouteRepository _repository;

  RouteNotifier(this._repository) : super(RouteState()) {
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _repository.getAllRoutes();
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (routes) => state = state.copyWith(isLoading: false, routes: routes),
    );
  }

  void refresh() {
    fetchRoutes();
  }
}

// Search provider
final routeSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered routes provider based on search
final filteredRoutesProvider = Provider<List<RouteModel>>((ref) {
  final routes = ref.watch(routeProvider).routes;
  final searchQuery = ref.watch(routeSearchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) return routes;

  return routes.where((route) {
    return route.name.toLowerCase().contains(searchQuery) ||
           route.shortName.toLowerCase().contains(searchQuery) ||
           route.stops.any((stop) => stop.name.toLowerCase().contains(searchQuery));
  }).toList();
});
