import type { StockGroup, StockItemsResponse } from '@/lib/types/stockItems'

const API_URL = process.env.NEXT_PUBLIC_API_URL

/**
 * Obtiene una página de productos filtrada por nombre y grupo.
 *
 * @param stockItemName Nombre parcial o completo del producto.
 * @param stockGroupID Grupo o `null` para no filtrar.
 * @param pageNumber Número de página a consultar.
 * @param pageSize Cantidad de productos por página.
 */
export async function getStockItems(
  stockItemName: string,
  stockGroupID: number | null,
  pageNumber: number,
  pageSize: number,
): Promise<StockItemsResponse> {
  const query = new URLSearchParams({
    stockItemName,
    pageNumber: String(pageNumber),
    pageSize: String(pageSize),
  })
  if (stockGroupID !== null) {
    query.set('stockGroupID', String(stockGroupID))
  }

  const res = await fetch(`${API_URL}/api/stock-items?${query}`)
  if (!res.ok) {
    throw new Error('No fue posible obtener los productos')
  }
  return res.json()
}

/** Obtiene los grupos de productos disponibles para filtrar el inventario. */
export async function getStockGroups(): Promise<StockGroup[]> {
  const res = await fetch(`${API_URL}/api/stock-items/groups`)
  if (!res.ok) {
    throw new Error('No fue posible obtener los grupos de productos')
  }
  return res.json()
}
