/** Producto mostrado en el listado de inventario. */
export interface StockItem {
  StockItemID: number
  NombreProducto: string
  NombreGrupoProducto: string
  CantidadTotalEnInventarios: number
}

/** Grupo disponible para filtrar productos. */
export interface StockGroup {
  StockGroupID: number
  NombreGrupoProducto: string
}

/** Filtros disponibles para consultar el inventario. */
export interface StockItemFilters {
  stockItemName: string
  stockGroupID: number | null
}

/** Respuesta paginada del listado de productos. */
export interface StockItemsResponse {
  page: number
  size: number
  totalCount: number
  totalPages: number
  data: StockItem[]
}
