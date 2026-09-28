import type { DeliveryMethod } from '@/lib/types/deliveryMethods'

const API_URL = process.env.NEXT_PUBLIC_API_URL

/** Obtiene los métodos de entrega disponibles para los filtros. */
export async function getDeliveryMethods(): Promise<DeliveryMethod[]> {
  const res = await fetch(`${API_URL}/api/delivery-methods`)
  if (!res.ok) {
    throw new Error('No fue posible obtener los métodos de entrega')
  }
  return res.json()
}
