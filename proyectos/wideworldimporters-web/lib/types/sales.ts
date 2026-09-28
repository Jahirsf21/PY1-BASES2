/** Factura mostrada en el listado de ventas. */
export interface Invoice {
  NumeroFactura: number
  FechaFactura: string
  NombreCliente: string
  NombreMetodoEntrega: string
  MontoFacturado: number
}

/** Filtros disponibles para consultar facturas. */
export interface InvoiceFilters {
  invoiceID: number | null
  invoiceDateFrom: string
  invoiceDateTo: string
  customerName: string
  deliveryMethodID: number | null
  minInvoiceAmount: number | null
  maxInvoiceAmount: number | null
}

/** Respuesta paginada del listado de facturas. */
export interface InvoicesResponse {
  page: number
  size: number
  totalCount: number
  totalPages: number
  data: Invoice[]
}
