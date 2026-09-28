import type { SupplierCategory, SuppliersResponse } from '@/lib/types/suppliers'

const API_URL = process.env.NEXT_PUBLIC_API_URL

/**
 * Obtiene una página de proveedores aplicando los filtros indicados.
 *
 * @param supplierName Nombre parcial o completo del proveedor.
 * @param supplierCategoryID Categoría o `null` para no filtrar.
 * @param deliveryMethodID Método de entrega o `null` para no filtrar.
 * @param pageNumber Número de página a consultar.
 * @param pageSize Cantidad de proveedores por página.
 */
export async function getSuppliers(supplierName: string, supplierCategoryID: number | null, deliveryMethodID: number | null, pageNumber: number, pageSize: number): Promise<SuppliersResponse> {
  const query = new URLSearchParams({
    supplierName,
    pageNumber: String(pageNumber),
    pageSize: String(pageSize),
  })
  if (supplierCategoryID !== null) {
    query.set('supplierCategoryID', String(supplierCategoryID))
  }
  if (deliveryMethodID !== null) {
    query.set('deliveryMethodID', String(deliveryMethodID))
  }
  const res = await fetch(`${API_URL}/api/suppliers?${query}`)
  if (!res.ok) {
    throw new Error('No fue posible obtener los proveedores')
  }
  return res.json()
}

/** Obtiene las categorías disponibles para filtrar proveedores. */
export async function getSupplierCategories(): Promise<SupplierCategory[]> {
  const res = await fetch(`${API_URL}/api/suppliers/categories`)
  if (!res.ok) {
    throw new Error('No fue posible obtener las categorías de proveedores')
  }
  return res.json()
}
