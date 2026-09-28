import type { InvoiceFilters, InvoicesResponse } from '@/lib/types/sales'

const API_URL = process.env.NEXT_PUBLIC_API_URL

/**
 * Obtiene una página de facturas aplicando filtros por número, fechas, cliente,
 * método de entrega y monto facturado.
 *
 * @param filters Filtros seleccionados en el listado de ventas.
 * @param pageNumber Número de página a consultar.
 * @param pageSize Cantidad de facturas por página.
 */
export async function getInvoices(filters: InvoiceFilters, pageNumber: number, pageSize: number): Promise<InvoicesResponse> {
  const query = new URLSearchParams({
    customerName: filters.customerName,
    pageNumber: String(pageNumber),
    pageSize: String(pageSize),
  })
  if (filters.invoiceID !== null) {
    query.set('invoiceID', String(filters.invoiceID))
  }
  if (filters.invoiceDateFrom) {
    query.set('invoiceDateFrom', filters.invoiceDateFrom)
  }
  if (filters.invoiceDateTo) {
    query.set('invoiceDateTo', filters.invoiceDateTo)
  }
  if (filters.deliveryMethodID !== null) {
    query.set('deliveryMethodID', String(filters.deliveryMethodID))
  } 
  if (filters.minInvoiceAmount !== null) {
    query.set('minInvoiceAmount', String(filters.minInvoiceAmount))
  }
  if (filters.maxInvoiceAmount !== null) {
    query.set('maxInvoiceAmount', String(filters.maxInvoiceAmount))
  }
  const res = await fetch(`${API_URL}/api/sales?${query}`)
  if (!res.ok) {
    throw new Error('No fue posible obtener las facturas')
  }
  return res.json()
}
