import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/services/delivery_cost_service.dart';
import 'package:shopwise_v1/services/installation_cost_service.dart';
import 'package:shopwise_v1/services/travel_cost_service.dart';
import 'package:shopwise_v1/services/true_cost_service.dart';

void main() {
  group('TravelCostService', () {
    const service = TravelCostService();

    test('calculates round-trip petrol bike cost correctly', () {
      final result = service.calculate(
        vehicleType: VehicleType.bike,
        distanceKm: 10,
        efficiency: 50,
        energyPrice: 100,
        tollCost: 20,
      );

      expect(result.oneWayDistanceKm, 10);
      expect(result.distanceKm, 20);
      expect(result.energyRequired, 0.4);
      expect(result.energyCost, 40);
      expect(result.tollCost, 20);
      expect(result.totalCost, 60);
      expect(result.isElectric, isFalse);
    });

    test('supports electric vehicle calculation', () {
      final result = service.calculate(
        vehicleType: VehicleType.electricCar,
        distanceKm: 30,
        efficiency: 6,
        energyPrice: 10,
        roundTrip: false,
      );

      expect(result.distanceKm, 30);
      expect(result.energyRequired, 5);
      expect(result.energyCost, 50);
      expect(result.totalCost, 50);
      expect(result.isElectric, isTrue);
    });

    test('clamps invalid negative inputs safely', () {
      final result = service.calculate(
        vehicleType: VehicleType.car,
        distanceKm: -10,
        efficiency: -5,
        energyPrice: -100,
        tollCost: -50,
      );

      expect(result.oneWayDistanceKm, 0);
      expect(result.distanceKm, 0);
      expect(result.efficiency, 1);
      expect(result.energyPrice, 0);
      expect(result.energyRequired, 0);
      expect(result.energyCost, 0);
      expect(result.tollCost, 0);
      expect(result.totalCost, 0);
    });

    test('vehicle profiles expose correct defaults', () {
      expect(TravelCostService.vehicleProfiles.length, 4);

      final bike = TravelCostService.vehicleProfiles.firstWhere(
        (profile) => profile.type == VehicleType.bike,
      );

      expect(bike.name, 'Petrol Bike');
      expect(bike.defaultEfficiency, 45);
      expect(bike.defaultEnergyPrice, 105);
      expect(bike.isElectric, isFalse);

      final electricCar = TravelCostService.vehicleProfiles.firstWhere(
        (profile) => profile.type == VehicleType.electricCar,
      );

      expect(electricCar.name, 'Electric Car');
      expect(electricCar.defaultEfficiency, 6);
      expect(electricCar.defaultEnergyPrice, 10);
      expect(electricCar.isElectric, isTrue);
    });
  });

  group('DeliveryCostService', () {
    const service = DeliveryCostService();

    test('self pickup is always free', () {
      final result = service.calculate(
        type: DeliveryType.selfPickup,
        shopDeliveryCost: 500,
        externalDeliveryCost: 800,
      );

      expect(result.type, DeliveryType.selfPickup);
      expect(result.cost, 0);
      expect(result.isFree, isTrue);
      expect(result.label, 'Self pickup');
    });

    test('shop delivery uses shop delivery cost', () {
      final result = service.calculate(
        type: DeliveryType.shopDelivery,
        shopDeliveryCost: 250,
      );

      expect(result.cost, 250);
      expect(result.isFree, isFalse);
      expect(result.label, 'Shop delivery');
    });

    test('external delivery uses external delivery cost', () {
      final result = service.calculate(
        type: DeliveryType.externalDelivery,
        externalDeliveryCost: 450,
      );

      expect(result.cost, 450);
      expect(result.label, 'External delivery');
    });

    test('negative delivery cost is clamped to zero', () {
      final result = service.calculate(
        type: DeliveryType.shopDelivery,
        shopDeliveryCost: -100,
      );

      expect(result.cost, 0);
      expect(result.isFree, isTrue);
    });
  });

  group('InstallationCostService', () {
    const service = InstallationCostService();

    test('installation not required is free', () {
      final result = service.calculate(
        type: InstallationType.notRequired,
        shopInstallationCost: 500,
        externalInstallationCost: 800,
      );

      expect(result.type, InstallationType.notRequired);
      expect(result.cost, 0);
      expect(result.isFree, isTrue);
      expect(result.label, 'Not required');
    });

    test('shop installation uses shop installation cost', () {
      final result = service.calculate(
        type: InstallationType.shopInstallation,
        shopInstallationCost: 350,
      );

      expect(result.cost, 350);
      expect(result.isFree, isFalse);
      expect(result.label, 'Shop installation');
    });

    test('external installation uses external installation cost', () {
      final result = service.calculate(
        type: InstallationType.externalInstallation,
        externalInstallationCost: 600,
      );

      expect(result.cost, 600);
      expect(result.label, 'External installation');
    });

    test('negative installation cost is clamped to zero', () {
      final result = service.calculate(
        type: InstallationType.externalInstallation,
        externalInstallationCost: -250,
      );

      expect(result.cost, 0);
      expect(result.isFree, isTrue);
    });
  });

  group('TrueCostService', () {
    const service = TrueCostService();

    test('combines product and additional purchase costs', () {
      final result = service.calculate(
        productPrice: 10000,
        travelCost: 200,
        deliveryCost: 300,
        installationCost: 500,
      );

      expect(result.productPrice, 10000);
      expect(result.travelCost, 200);
      expect(result.deliveryCost, 300);
      expect(result.installationCost, 500);
      expect(result.additionalCost, 1000);
      expect(result.totalCost, 11000);
    });

    test('defaults additional costs to zero', () {
      final result = service.calculate(productPrice: 7500);

      expect(result.productPrice, 7500);
      expect(result.travelCost, 0);
      expect(result.deliveryCost, 0);
      expect(result.installationCost, 0);
      expect(result.additionalCost, 0);
      expect(result.totalCost, 7500);
    });

    test('clamps negative costs safely', () {
      final result = service.calculate(
        productPrice: -1000,
        travelCost: -100,
        deliveryCost: -200,
        installationCost: -300,
      );

      expect(result.productPrice, 0);
      expect(result.travelCost, 0);
      expect(result.deliveryCost, 0);
      expect(result.installationCost, 0);
      expect(result.additionalCost, 0);
      expect(result.totalCost, 0);
    });
  });
}
