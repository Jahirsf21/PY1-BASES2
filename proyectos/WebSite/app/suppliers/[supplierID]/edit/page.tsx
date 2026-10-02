'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { useParams } from 'next/navigation'
import { getSupplierForEdit } from '@/app/api/suppliers'
import { SupplierForm } from '@/app/suppliers/supplier-form'
import type { SupplierEdit, SupplierRouteParams } from '@/lib/types/suppliers'

export default function EditSupplierPage() {
  const { supplierID } = useParams<SupplierRouteParams>()
  const [supplier, setSupplier] = useState<SupplierEdit | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    const id = Number(supplierID)
    if (!/^\d+$/.test(supplierID) || !Number.isSafeInteger(id) || id < 1 || id > 2147483647) {
      Promise.resolve().then(() => { if (!cancelled) setError('Proveedor no encontrado') })
    } else {
      getSupplierForEdit(id).then((data) => { if (!cancelled) setSupplier(data) })
        .catch((reason) => { if (!cancelled) setError(reason instanceof Error ? reason.message : 'No fue posible cargar el proveedor') })
    }
    return () => { cancelled = true }
  }, [supplierID])

  if (supplier && !error) return <SupplierForm key={supplier.SupplierID} initial={supplier} />
  return (
    <main className="flex min-w-0 flex-1 bg-muted/30"><div className="mx-auto w-full max-w-5xl space-y-4 px-4 py-6 sm:px-8 sm:py-8">
      <Link href={`/suppliers/${supplierID}`} className="text-sm text-muted-foreground hover:underline">Volver al detalle</Link>
      <p role={error ? 'alert' : undefined} className={`rounded-lg border bg-card p-4 text-sm ${error ? 'text-destructive' : 'text-muted-foreground'}`}>{error ?? 'Cargando proveedor...'}</p>
    </div></main>
  )
}
