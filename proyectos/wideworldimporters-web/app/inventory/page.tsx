'use client'

import type { SubmitEvent } from 'react'
import { useEffect, useState } from 'react'
import { ChevronDownIcon, ChevronLeftIcon, ChevronRightIcon, RotateCcwIcon, SearchIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { DropdownMenu, DropdownMenuContent, DropdownMenuRadioGroup, DropdownMenuRadioItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { getStockGroups, getStockItems } from '@/app/api/stockItems'
import type { StockGroup, StockItemFilters, StockItemsResponse } from '@/lib/types/stockItems'

const PAGE_SIZE = 10

const initialFilters: StockItemFilters = {
  stockItemName: '',
  stockGroupID: null,
}

export default function InventoryPage() {
  const [stockItemName, setStockItemName] = useState('')
  const [stockGroupID, setStockGroupID] = useState<StockItemFilters['stockGroupID']>(null)
  const [filters, setFilters] = useState<StockItemFilters>(initialFilters)
  const [pageNumber, setPageNumber] = useState(1)
  const [stockItemsResponse, setStockItemsResponse] = useState<StockItemsResponse | null>(null)
  const [groups, setGroups] = useState<StockGroup[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function loadData() {
      setIsLoading(true)
      setError(null)
      try {
        const itemsData = await getStockItems(filters.stockItemName, filters.stockGroupID, pageNumber, PAGE_SIZE)
        setStockItemsResponse(itemsData)
      } catch (error) {
        setError(error instanceof Error ? error.message : 'No fue posible obtener los productos')
      } finally {
        setIsLoading(false)
      }
    }

    void loadData()
  }, [filters, pageNumber])

  useEffect(() => {
    getStockGroups().then(setGroups).catch(() => {})
  }, [])

  function handleSubmit(event: SubmitEvent<HTMLFormElement>) {
    event.preventDefault()
    setFilters({ stockItemName, stockGroupID })
    setPageNumber(1)
  }

  function resetFilters() {
    setStockItemName('')
    setStockGroupID(null)
    setFilters(initialFilters)
    setPageNumber(1)
  }

  const stockItems = stockItemsResponse?.data ?? []
  const totalPages = stockItemsResponse?.totalPages ?? 0
  const totalCount = stockItemsResponse?.totalCount ?? 0

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
          <h1 className="text-2xl font-semibold tracking-tight">Inventario</h1>
          <p className="text-sm text-muted-foreground">
            {totalCount} {totalCount === 1 ? 'Producto' : 'Productos'}
          </p>
        </div>

        <div className="rounded-lg border bg-card p-4 shadow-sm">
          <form className="grid gap-4 md:grid-cols-[minmax(0,1fr)_220px_auto] md:items-end" onSubmit={handleSubmit}>
            <div className="grid gap-2">
              <Label htmlFor="stockItemName">Nombre del producto</Label>
              <Input
                id="stockItemName"
                placeholder="Buscar por nombre"
                value={stockItemName}
                onChange={(event) => setStockItemName(event.target.value)}
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="stockGroup">Grupo de productos</Label>
              <DropdownMenu>
                <DropdownMenuTrigger
                  id="stockGroup"
                  type="button"
                  className="flex h-8 w-full items-center justify-between gap-2 rounded-lg border border-input bg-transparent px-2.5 text-left text-sm outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 dark:bg-input/30"
                >
                  <span className="min-w-0 truncate">
                    {groups.find((group) => group.StockGroupID === stockGroupID)?.NombreGrupoProducto ?? 'Todos los grupos'}
                  </span>
                  <ChevronDownIcon className="size-4 shrink-0" aria-hidden="true" />
                </DropdownMenuTrigger>
                <DropdownMenuContent className="max-w-[calc(100vw-2rem)]">
                  <DropdownMenuRadioGroup
                    value={stockGroupID === null ? '' : String(stockGroupID)}
                    onValueChange={(value) => setStockGroupID(value === '' ? null : Number(value))}
                  >
                    <DropdownMenuRadioItem value="" closeOnClick>Todos los grupos</DropdownMenuRadioItem>
                    {groups.map((group) => (
                      <DropdownMenuRadioItem key={group.StockGroupID} value={String(group.StockGroupID)} closeOnClick>
                        {group.NombreGrupoProducto}
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
            <h2 className="font-medium">Listado de productos</h2>
            <span className="text-sm text-muted-foreground">
              {isLoading && stockItems.length > 0
                ? 'Actualizando...'
                : `Página ${pageNumber} de ${totalPages}`}
            </span>
          </div>

          <div className="min-h-[20rem] md:min-h-[26rem]" aria-busy={isLoading}>
            {isLoading && stockItems.length === 0 && (
              <p className="flex h-32 items-center justify-center px-4 text-center text-sm text-muted-foreground">
                Cargando productos...
              </p>
            )}

            {!isLoading && error && (
              <p className="flex h-32 items-center justify-center px-4 text-center text-sm text-destructive" role="alert">
                {error}
              </p>
            )}

            {!isLoading && !error && stockItems.length === 0 && (
              <p className="flex h-32 items-center justify-center px-4 text-center text-sm text-muted-foreground">
                No se encontraron productos con los filtros seleccionados.
              </p>
            )}

            {!error && stockItems.length > 0 && (
              <>
                <ul className="divide-y md:hidden">
                  {stockItems.map((item) => (
                    <li key={item.StockItemID} className="space-y-3 px-4 py-4">
                      <p className="break-words text-sm font-medium">{item.NombreProducto}</p>
                      <dl className="grid grid-cols-2 gap-x-4 text-sm">
                        <div className="min-w-0">
                          <dt className="text-xs text-muted-foreground">Grupos</dt>
                          <dd className="break-words">{item.NombreGrupoProducto}</dd>
                        </div>
                        <div className="min-w-0">
                          <dt className="text-xs text-muted-foreground">Cantidad en inventario</dt>
                          <dd>{item.CantidadTotalEnInventarios}</dd>
                        </div>
                      </dl>
                    </li>
                  ))}
                </ul>

                <div className="hidden md:block">
                  <Table className="min-w-[640px] table-fixed">
                    <colgroup>
                      <col className="w-[45%]" />
                      <col className="w-[35%]" />
                      <col className="w-[20%]" />
                    </colgroup>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Nombre</TableHead>
                        <TableHead>Grupos</TableHead>
                        <TableHead>Cantidad en inventario</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {stockItems.map((item) => (
                        <TableRow key={item.StockItemID}>
                          <TableCell className="truncate" title={item.NombreProducto}>
                            {item.NombreProducto}
                          </TableCell>
                          <TableCell className="truncate" title={item.NombreGrupoProducto}>
                            {item.NombreGrupoProducto}
                          </TableCell>
                          <TableCell>{item.CantidadTotalEnInventarios}</TableCell>
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
              Mostrando {stockItems.length} de {totalCount} Productos
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
                <Label htmlFor="inventoryPageNumber" className="sr-only">Número de página</Label>
                <Input
                  key={pageNumber}
                  id="inventoryPageNumber"
                  name="pageNumber"
                  type="number"
                  min={1}
                  max={totalPages}
                  step={1}
                  required
                  defaultValue={pageNumber}
                  disabled={isLoading || totalPages === 0}
                  onKeyDown={(event) => { if (event.key === '-') event.preventDefault() }}
                  onChange={(event) => {
                    if (event.currentTarget.value !== '' && Number(event.currentTarget.value) < 1) {
                      event.currentTarget.value = '1'
                    }
                  }}
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
