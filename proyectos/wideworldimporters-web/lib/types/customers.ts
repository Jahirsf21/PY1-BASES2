/** Respuesta estándar para los endpoints que devuelven datos paginados. */
export interface PaginatedResponse<T> {
  page: number
  size: number
  totalCount: number
  totalPages: number
  data: T[]
}

/** Cliente mostrado en el listado principal de clientes. */
export interface Customer {
  CustomerID: number
  NombreCliente: string
  NombreCategoriaCliente: string
  NombreMetodoEntrega: string
}

/** Cliente disponible para asignar como cliente por facturar. */
export interface BillToCustomer {
  CustomerID: number
  NombreCliente: string
}

/** Categoría a la que puede pertenecer un cliente. */
export interface CustomerCategory {
  CustomerCategoryID: number
  NombreCategoria: string
}

/** Agrupación de compra que puede asociarse a un cliente. */
export interface BuyingGroup {
  BuyingGroupID: number
  NombreGrupoCompra: string
}

/** Información general de un cliente. */
export interface CustomerDetail {
  CustomerID: number
  NombreCliente: string
  NombreCategoriaCliente: string
  NombreGrupoCompra: string | null
  NombreClientePorFacturar: string
  NombreMetodoEntrega: string
  DiasGraciaPago: number
  SitioWeb: string | null
}

/** Datos de los contactos principal y alternativo de un cliente. */
export interface CustomerContact {
  NombreContactoPrincipal: string | null
  TelefonoPrincipal: string | null
  FaxPrincipal: string | null
  CorreoPrincipal: string | null
  NombreContactoAlternativo: string | null
  TelefonoAlternativo: string | null
  FaxAlternativo: string | null
  CorreoAlternativo: string | null
}

/** Direcciones postal y de entrega, junto con la ubicación geográfica del cliente. */
export interface CustomerAddress {
  DireccionEntrega1: string
  DireccionEntrega2: string | null
  CiudadEntrega: string
  ProvinciaEntrega: string
  PaisEntrega: string
  CodigoPostalEntrega: string
  DireccionPostal1: string
  DireccionPostal2: string | null
  CiudadPostal: string
  ProvinciaPostal: string
  PaisPostal: string
  CodigoPostalPostal: string
  Latitud: number | null
  Longitud: number | null
}

/** Filtros disponibles para consultar el listado de clientes. */
export interface CustomerFilters {
  customerName: string
  customerCategoryID: number | null
  deliveryMethodID: number | null
}

/** Respuesta paginada del listado principal de clientes. */
export type CustomersResponse = PaginatedResponse<Customer>

/** Respuesta paginada de clientes disponibles para facturación. */
export type BillToCustomersResponse = PaginatedResponse<BillToCustomer>
