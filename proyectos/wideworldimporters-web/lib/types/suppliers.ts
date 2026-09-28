/** Proveedor mostrado en el listado principal. */
export interface Supplier {
  SupplierID: number
  NombreProveedor: string
  NombreCategoriaProveedor: string
  NombreMetodoEntrega: string | null
}

/** Categoría disponible para filtrar proveedores. */
export interface SupplierCategory {
  SupplierCategoryID: number
  NombreCategoriaProveedor: string
}

/** Filtros disponibles para consultar proveedores. */
export interface SupplierFilters {
  supplierName: string
  supplierCategoryID: number | null
  deliveryMethodID: number | null
}

/** Respuesta paginada del listado de proveedores. */
export interface SuppliersResponse {
  page: number
  size: number
  totalCount: number
  totalPages: number
  data: Supplier[]
}
