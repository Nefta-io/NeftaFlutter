import 'nefta.dart';

abstract class GameEvent {
  int get _eventType;
  int get _category;
  int get _subCategory;

  String? name;
  /// Value field, must be non-negative.
  int value = 0;
  String? customString;

  void record() {
    Nefta.Record(_eventType, _category, _subCategory, name, value, customString);
  }
}

enum ProgressionType {
  Achievement(0),
  GameplayUnit(1),
  ItemLevel(2),
  Unlock(3),
  PlayerLevel(4),
  Task(5),
  Other(6);
  final int value;
  const ProgressionType(this.value);
  static ProgressionType fromInt(int val) {
    return ProgressionType.values.firstWhere((e) => e.value == val, orElse: () => ProgressionType.Other);
  }
}

enum ProgressionStatus {
  Start(0),
  Complete(1),
  Fail(2);
  final int value;
  const ProgressionStatus(this.value);
  static ProgressionStatus fromInt(int val) {
    return ProgressionStatus.values.firstWhere((e) => e.value == val, orElse: () => ProgressionStatus.Start);
  }
}

enum ProgressionSource {
  Undefined(0),
  CoreContent(1),
  OptionalContent(2),
  Boss(3),
  Social(4),
  SpecialEvent(5),
  Other(6);
  final int value;
  const ProgressionSource(this.value);
  static ProgressionSource fromInt(int val) {
    return ProgressionSource.values.firstWhere((e) => e.value == val, orElse: () => ProgressionSource.Undefined);
  }
}

class ProgressionEvent extends GameEvent {
  ProgressionType type = ProgressionType.Other;
  ProgressionStatus status = ProgressionStatus.Start;
  ProgressionSource source = ProgressionSource.Undefined;

  @override
  int get _eventType => 1;
  @override
  int get _category => type.value * 3 + status.value;
  @override
  int get _subCategory => source.value;

  ProgressionEvent(this.type, this.status, { this.source=ProgressionSource.Undefined, String? name, int value=0, String? customString }) {
    this.name = name;
    this.value = value;
    this.customString = customString;
  }
}

class PurchaseEvent extends GameEvent {
  int _currency = 0;

  @override
  int get _eventType => 4;
  @override
  int get _category => 0;
  @override
  int get _subCategory => _currency;

  double get price => value / 1000000;

  /// Price field, must be non-negative.
  set price(double value) {
    this.value = (value * 1000000).round();
  }

  PurchaseEvent(String name, double price, String currency, { String? customString }) {
    this.name = name;
    this.price = price;
    assert(currency.length == 3, "Invalid ISO 4217 currency");
    _currency = currency.codeUnitAt(0) | (currency.codeUnitAt(1) << 8) | (currency.codeUnitAt(2) << 16);
    this.customString = customString;
  }
}

enum ResourceCategory {
  Other(0),
  SoftCurrency(1),
  PremiumCurrency(2),
  Resource(3),
  Consumable(4),
  CosmeticItem(5),
  CoreItem(6),
  Chest(7),
  Experience(8);
  final int value;
  const ResourceCategory(this.value);
  static ResourceCategory fromInt(int val) {
    return ResourceCategory.values.firstWhere((e) => e.value == val, orElse: () => ResourceCategory.Other);
  }
}

abstract class ResourceEvent extends GameEvent {
  ResourceCategory resourceCategory = ResourceCategory.Other;

  @override
  int get _category => resourceCategory.value;

  int get quantity => value;
  /// Quantity field, must be non-negative.
  set quantity(int value) {
    this.value = value;
  }
}

enum ReceiveMethod {
  Undefined(0),
  LevelEnd(1),
  Reward(2),
  Loot(3),
  Shop(4),
  IAP(5),
  Create(6),
  Other(7);
  final int value;
  const ReceiveMethod(this.value);
  static ReceiveMethod fromInt(int val) {
    return ReceiveMethod.values.firstWhere((e) => e.value == val, orElse: () => ReceiveMethod.Undefined);
  }
}

class ReceiveEvent extends ResourceEvent {
  ReceiveMethod method = ReceiveMethod.Undefined;

  @override
  int get _eventType => 2;

  @override
  int get _subCategory => method.value;

  ReceiveEvent(ResourceCategory category, { this.method=ReceiveMethod.Undefined, String? name, int value=0, String? customString }) {
    resourceCategory = category;
    this.name = name;
    this.value = value;
    this.customString = customString;
  }
}

enum SpendMethod {
  Undefined(0),
  Boost(1),
  Continuity(2),
  Create(3),
  Unlock(4),
  Upgrade(5),
  Shop(6),
  Other(7);
  final int value;
  const SpendMethod(this.value);
  static SpendMethod fromInt(int val) {
    return SpendMethod.values.firstWhere((e) => e.value == val, orElse: () => SpendMethod.Undefined);
  }
}

class SpendEvent extends ResourceEvent {
  SpendMethod method = SpendMethod.Undefined;

  @override
  int get _eventType => 3;

  @override
  int get _subCategory => method.value;

  SpendEvent(ResourceCategory category, { this.method=SpendMethod.Undefined, String? name, int value=0, String? customString }) {
    resourceCategory = category;
    this.name = name;
    this.value = value;
    this.customString = customString;
  }
}