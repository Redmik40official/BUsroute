import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/route_model.dart';

final _log = Logger();

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final dio = ref.read(dioProvider);
  return RouteRepository(dio);
});

class RouteRepository {
  final Dio _dio;

  RouteRepository(this._dio);

  Future<Either<Failure, List<RouteModel>>> getAllRoutes() async {
    try {
      final response = await _dio.get('/routes');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['routes'] != null) {
          final List<dynamic> routesJson = data['routes'];
          final routes = routesJson.map((json) => RouteModel.fromJson(json)).toList();
          return Right(routes);
        }
        return const Left(ServerFailure('Invalid response format'));
      }
      return Left(ServerFailure('Failed to fetch routes: ${response.statusCode}'));
    } on DioException catch (e) {
      _log.e('[RouteRepository] DioError: ${e.message}');
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to connect to server'));
    } catch (e) {
      _log.e('[RouteRepository] Exception: $e');
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }

  Future<Either<Failure, RouteModel>> getRouteDetails(String routeId) async {
    try {
      final response = await _dio.get('/routes/$routeId');
      
      if (response.statusCode == 200) {
        if (response.data != null) {
          return Right(RouteModel.fromJson(response.data));
        }
        return const Left(ServerFailure('Invalid response format'));
      }
      return Left(ServerFailure('Failed to fetch route details: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data?['error'] ?? 'Failed to connect to server'));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred'));
    }
  }
}
