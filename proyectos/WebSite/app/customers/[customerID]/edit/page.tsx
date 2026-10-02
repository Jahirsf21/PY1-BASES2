'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useParams } from 'next/navigation'
import { getCustomerForEdit } from '@/app/api/customers'
import { CustomerForm } from '@/app/customers/customer-form'
import type { CustomerEdit, CustomerRouteParams } from '@/lib/types/customers'

export default function EditCustomerPage() {
  const { customerID } = useParams<CustomerRouteParams>()
  const [customer, setCustomer] = useState<CustomerEdit | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false
    const id = Number(customerID)
    if (!/^\d+$/.test(customerID) || !Number.isSafeInteger(id) || id < 1 || id > 2147483647) {
      Promise.resolve().then(() => {
        if (!cancelled) {
          setError('Cliente no encontrado')
          setLoading(false)
        }
      })
    } else {
      getCustomerForEdit(id).then((data) => {
        if (!cancelled) setCustomer(data)
      }).catch((reason) => {
        if (!cancelled) setError(reason instanceof Error ? reason.message : 'No fue posible cargar el cliente')
      }).finally(() => {
        if (!cancelled) setLoading(false)
      })
    }
    return () => { cancelled = true }
  }, [customerID])

  if (customer && !error) return <CustomerForm key={customer.CustomerID} initial={customer} />

  return (
    <main className="flex min-w-0 flex-1 bg-muted/30">
      <div className="mx-auto w-full max-w-5xl space-y-4 px-4 py-6 sm:px-8 sm:py-8">
        <Link href={`/customers/${customerID}`} className="text-sm text-muted-foreground hover:underline">Volver al detalle</Link>
        <p role={error ? 'alert' : undefined} className={`rounded-lg border bg-card p-4 text-sm ${error ? 'text-destructive' : 'text-muted-foreground'}`}>
          {error ?? (loading ? 'Cargando cliente...' : 'Cliente no encontrado')}
        </p>
      </div>
    </main>
  )
}
