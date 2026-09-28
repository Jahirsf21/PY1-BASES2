'use client'

import type { SubmitEvent } from 'react'
import { useEffect, useState } from 'react'
import { ChevronDownIcon, ChevronLeftIcon, ChevronRightIcon, RotateCcwIcon, SearchIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuRadioGroup, DropdownMenuRadioItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { getDeliveryMethods } from '@/app/api/application'
import { getSupplierCategories, getSuppliers } from '@/app/api/suppliers'
import type { DeliveryMethod } from '@/lib/types/deliveryMethods'
import type { SupplierCategory, SupplierFilters, SuppliersResponse } from '@/lib/types/suppliers'

const PAGE_SIZE = 10

const initialFilters: SupplierFilters = {
  supplierName: '',
  supplierCategoryID: null,
  deliveryMethodID: null,
}

export default function SuppliersPage() {
  const [supplierName, setSupplierName] = useState('')
  const [supplierCategoryID, setSupplierCategoryID] = useState<SupplierFilters['supplierCategoryID']>(null)
  const [deliveryMethodID, setDeliveryMethodID] = useState<SupplierFilters['deliveryMethodID']>(null)
  const [filters, setFilters] = useState<SupplierFilters>(initialFilters)
  const [pageNumber, setPageNumber] = useState(1)
  const [suppliersResponse, setSuppliersResponse] = useState<SuppliersResponse | null>(null)
  const [categories, setCategories] = useState<SupplierCategory[]>([])
  const [deliveryMethods, setDeliveryMethods] = useState<DeliveryMethod[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function loadData() {
      setIsLoading(true)
      setError(null)
      try {
        const suppliersData = await getSuppliers(filters.supplierName, filters.supplierCategoryID, filters.deliveryMethodID, pageNumber, PAGE_SIZE)
        setSuppliersResponse(suppliersData)
      } catch (error) {
        setError(error instanceof Error ? error.message : 'No fue posible obtener los proveedores')
      } finally {
        setIsLoading(false)
      }
    }

    void loadData()
  }, [filters, pageNumber])

  useEffect(() => {
    getSupplierCategories().then(setCategories).catch(() => {})
    getDeliveryMethods().then(setDeliveryMethods).catch(() => {})
  }, [])

  function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault()
    setFilters({ supplierName, supplierCategoryID, deliveryMethodID })
    setPageNumber(1)
  }

  function resetFilters() {
    setSupplierName('')
    setSupplierCategoryID(null)
    setDeliveryMethodID(null)
    setFilters(initialFilters)
    setPageNumber(1)
  }

  const suppliers = suppliersResponse?.data ?? []
  const totalPages = suppliersResponse?.totalPages ?? 0
  const totalCount = suppliersResponse?.totalCount ?? 0

  function handlePageSubmit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault()
    const page = Number(new FormData(event.currentTarget).get('pageNumber'))
    if (Number.isInteger(page) && page >= 1 && page <= totalPages) {
      setPageNumber(page)
    }
  }

  return (
    <main className="flex min-w-0 flex-1 bg-muted/30">
      <section className="mx-auto flex w-full max-w-7xl flex-col gap-4 px-4 py-6 sm:gap-6 sm:px-8 sm:py-8">
        <div className="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
          <h1 className="text-2xl font-semibold tracking-tight">Proveedores</h1>
          <p className="text-sm text-muted-foreground">
            {totalCount} {totalCount === 1 ? 'Proveedor' : 'Proveedores'}
          </p>
        </div>

        <div className="rounded-lg border bg-card p-4 shadow-sm">
          <form className="grid gap-4 md:grid-cols-2 md:items-end lg:grid-cols-[minmax(0,1fr)_190px_190px_auto]" onSubmit={handleSubmit}>
            <div className="grid gap-2">
              <Label htmlFor="supplierName">Nombre del proveedor</Label>
              <Input
                id="supplierName"
                placeholder="Buscar por nombre"
                value={supplierName}
                onChange={(event) => setSupplierName(event.target.value)}
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="supplierCategory">Categoría</Label>
              <DropdownMenu>
                <DropdownMenuTrigger
                  id="supplierCategory"
                  type="button"
                  className="flex h-8 w-full items-center justify-between gap-2 rounded-lg border border-input bg-transparent px-2.5 text-left text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
                >
                  <span className="min-w-0 truncate">
                    {categories.find((category) => category.SupplierCategoryID === supplierCategoryID)?.NombreCategoriaProveedor ?? 'Todas las categorías'}
                  </span>
                  <ChevronDownIcon className="size-4 shrink-0" aria-hidden="true" />
                </DropdownMenuTrigger>
                <DropdownMenuContent className="max-w-[calc(100vw-2rem)]">
                  <DropdownMenuRadioGroup
                    value={supplierCategoryID === null ? '' : String(supplierCategoryID)}
                    onValueChange={(value) => setSupplierCategoryID(value === '' ? null : Number(value))}
                  >
                    <DropdownMenuRadioItem value="" closeOnClick>Todas las categorías</DropdownMenuRadioItem>
                    {categories.map((category) => (
                      <DropdownMenuRadioItem key={category.SupplierCategoryID} value={String(category.SupplierCategoryID)} closeOnClick>
                        {category.NombreCategoriaProveedor}
                      </DropdownMenuRadioItem>
                    ))}
                  </DropdownMenuRadioGroup>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <div className="grid gap-2">
              <Label htmlFor="supplierDeliveryMethod">Método de entrega</Label>
              <DropdownMenu>
                <DropdownMenuTrigger
                  id="supplierDeliveryMethod"
                  type="button"
                  className="flex h-8 w-full items-center justify-between gap-2 rounded-lg border border-input bg-transparent px-2.5 text-left text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
                >
                  <span className="min-w-0 truncate">
                    {deliveryMethods.find((method) => method.DeliveryMethodID === deliveryMethodID)?.NombreMetodoEntrega ?? 'Todos los métodos'}
                  </span>
                  <ChevronDownIcon className="size-4 shrink-0" aria-hidden="true" />
                </DropdownMenuTrigger>
                <DropdownMenuContent className="max-w-[calc(100vw-2rem)]">
                  <DropdownMenuRadioGroup
                    value={deliveryMethodID === null ? '' : String(deliveryMethodID)}
                    onValueChange={(value) => setDeliveryMethodID(value === '' ? null : Number(value))}
                  >
                    <DropdownMenuRadioItem value="" closeOnClick>Todos los métodos</DropdownMenuRadioItem>
                    {deliveryMethods.map((method) => (
                      <DropdownMenuRadioItem key={method.DeliveryMethodID} value={String(method.DeliveryMethodID)} closeOnClick>
                        {method.NombreMetodoEntrega}
                      </DropdownMenuRadioItem>
                    ))}
                  </DropdownMenuRadioGroup>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>

            <div className="flex flex-wrap gap-2">
              <Button type="submit">
                <SearchIcon data-icon="inline-start" />
                Buscar
              </Button>
              <Button type="button" variant="outline" onClick={resetFilters}>
                <RotateCcwIcon data-icon="inline-start" />
                Limpiar
              </Button>
            </div>
          </form>
        </div>

        <div className="overflow-hidden rounded-lg border bg-card shadow-sm">
          <div className="flex items-center justify-between border-b px-4 py-3">
            <h2 className="font-medium">Listado de proveedores</h2>
            <span className="text-sm text-muted-foreground">
              {isLoading && suppliers.length > 0
                ? 'Actualizando...'
                : `Página ${pageNumber} de ${totalPages}`}
            </span>
          </div>

          <div className="min-h-[20rem] md:min-h-[26rem]" aria-busy={isLoading}>
            {isLoading && suppliers.length === 0 && (
              <p className="flex h-32 items-center justify-center px-4 text-center text-sm text-muted-foreground">
                Cargando proveedores...
              </p>
            )}

            {!isLoading && error && (
              <p className="flex h-32 items-center justify-center px-4 text-center text-sm text-destructive" role="alert">
                {error}
              </p>
            )}

            {!isLoading && !error && suppliers.length === 0 && (
              <p className="flex h-32 items-center justify-center px-4 text-center text-sm text-muted-foreground">
                No se encontraron proveedores con los filtros seleccionados.
              </p>
            )}

            {!error && suppliers.length > 0 && (
              <>
                <ul className="divide-y md:hidden">
                  {suppliers.map((supplier) => (
                    <li key={supplier.SupplierID} className="space-y-3 px-4 py-4">
                      <p className="break-words text-sm font-medium">{supplier.NombreProveedor}</p>
                      <dl className="grid grid-cols-2 gap-x-4 text-sm">
                        <div className="min-w-0">
                          <dt className="text-xs text-muted-foreground">Categoría</dt>
                          <dd className="break-words">{supplier.NombreCategoriaProveedor}</dd>
                        </div>
                        <div className="min-w-0">
                          <dt className="text-xs text-muted-foreground">Método de entrega</dt>
                          <dd className="break-words">{supplier.NombreMetodoEntrega ?? 'No asignado'}</dd>
                        </div>
                      </dl>
                    </li>
                  ))}
                </ul>

                <div className="hidden md:block">
                  <Table className="min-w-[640px] table-fixed">
                    <colgroup>
                      <col className="w-[45%]" />
                      <col className="w-[30%]" />
                      <col className="w-[25%]" />
                    </colgroup>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Nombre</TableHead>
                        <TableHead>Categoría</TableHead>
                        <TableHead>Método de entrega</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {suppliers.map((supplier) => (
                        <TableRow key={supplier.SupplierID}>
                          <TableCell className="truncate" title={supplier.NombreProveedor}>
                            {supplier.NombreProveedor}
                          </TableCell>
                          <TableCell className="truncate" title={supplier.NombreCategoriaProveedor}>
                            {supplier.NombreCategoriaProveedor}
                          </TableCell>
                          <TableCell className="truncate" title={supplier.NombreMetodoEntrega ?? 'No asignado'}>
                            {supplier.NombreMetodoEntrega ?? 'No asignado'}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </div>
              </>
            )}
          </div>

          <div className="flex flex-col items-center gap-3 border-t px-4 py-3 sm:flex-row sm:justify-between">
            <p className="text-center text-sm text-muted-foreground sm:text-left">
              Mostrando {suppliers.length} de {totalCount} Proveedores
            </p>
            <div className="flex flex-col items-center gap-2 sm:flex-row">
              <div className="flex justify-center gap-2">
                <Button
                  type="button"
                  variant="outline"
                  disabled={pageNumber === 1 || isLoading}
                  onClick={() => setPageNumber((page) => page - 1)}
                >
                  <ChevronLeftIcon data-icon="inline-start" />
                  Anterior
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  disabled={pageNumber >= totalPages || isLoading}
                  onClick={() => setPageNumber((page) => page + 1)}
                >
                  Siguiente
                  <ChevronRightIcon data-icon="inline-end" />
                </Button>
              </div>
              <form className="flex items-center justify-center gap-2" onSubmit={handlePageSubmit}>
                <Label htmlFor="supplierPageNumber" className="sr-only">Número de página</Label>
                <Input
                  key={pageNumber}
                  id="supplierPageNumber"
                  name="pageNumber"
                  type="number"
                  min={1}
                  max={totalPages}
                  step={1}
                  required
                  defaultValue={pageNumber}
                  disabled={isLoading || totalPages === 0}
                  className="w-16 text-center"
                />
                <Button type="submit" variant="outline" disabled={isLoading || totalPages === 0}>
                  Ir
                </Button>
              </form>
            </div>
          </div>
        </div>
      </section>
    </main>
  )
}
