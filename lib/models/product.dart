class Product {
  static const Object _unset = Object();

  const Product({
    this.id,
    required this.nome,
    required this.categoria,
    required this.quantidade,
    required this.pontoPedido,
    this.barcode,
    required this.lote,
    required this.dataValidade,
    required this.trend,
    required this.galpaoZerado,
    this.lastUpdated,
  });

  final int? id;
  final String nome;
  final String categoria;
  final int quantidade;
  final int pontoPedido;
  final String? barcode;
  final String lote;
  final DateTime dataValidade;
  final int trend;
  final bool galpaoZerado;
  final DateTime? lastUpdated;

  bool get outOfStock => quantidade <= 0;
  bool get lowStock => quantidade > 0 && quantidade <= pontoPedido;
  bool get nearExpiry => dataValidade.difference(DateTime.now()).inDays <= 7;

  Product copyWith({
    int? id,
    String? nome,
    String? categoria,
    int? quantidade,
    int? pontoPedido,
    Object? barcode = _unset,
    String? lote,
    DateTime? dataValidade,
    int? trend,
    bool? galpaoZerado,
    DateTime? lastUpdated,
  }) {
    return Product(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      quantidade: quantidade ?? this.quantidade,
      pontoPedido: pontoPedido ?? this.pontoPedido,
      barcode: identical(barcode, _unset) ? this.barcode : barcode as String?,
      lote: lote ?? this.lote,
      dataValidade: dataValidade ?? this.dataValidade,
      trend: trend ?? this.trend,
      galpaoZerado: galpaoZerado ?? this.galpaoZerado,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nome': nome,
      'categoria': categoria,
      'quantidade': quantidade,
      'ponto_pedido': pontoPedido,
      'barcode': barcode,
      'lote': lote,
      'data_validade': dataValidade.toIso8601String(),
      'trend': trend,
      'galpao_zerado': galpaoZerado ? 1 : 0,
      'last_updated': (lastUpdated ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      categoria: map['categoria'] as String,
      quantidade: map['quantidade'] as int,
      pontoPedido: map['ponto_pedido'] as int,
      barcode: map['barcode'] as String?,
      lote: map['lote'] as String,
      dataValidade: DateTime.parse(map['data_validade'] as String),
      trend: map['trend'] as int,
      galpaoZerado: (map['galpao_zerado'] as int) == 1,
      lastUpdated: map['last_updated'] == null
          ? null
          : DateTime.parse(map['last_updated'] as String),
    );
  }
}
