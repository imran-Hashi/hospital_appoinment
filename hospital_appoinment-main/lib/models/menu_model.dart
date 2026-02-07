class Menu {
  final int id;
  final String name;
  final String route;
  final String icon;
  final int? parentId;

  Menu({
    required this.id,
    required this.name,
    required this.route,
    required this.icon,
    this.parentId,
  });
// waa meesha laga xukumo menu ka sidebar sidoo kale waa placeholder kuu haaaya xogta
  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      name: json['name'],
      route: json['route'],
      icon: json['icon'],
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'route': route,
      'icon': icon,
      'parent_id': parentId,
    };
  }
}
