# Filament v5.x Widgets

## Widget Types
- `StatsOverviewWidget` — KPI cards with stats
- `ChartWidget` — line, bar, pie charts
- `TableWidget` — mini tables on dashboard
- Custom `Widget` — Blade-based custom widgets

## Stats Overview Widget

```php
class RevenueOverviewWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        return [
            Stat::make('Total Revenue', '$' . number_format(Order::sum('total'), 2))
                ->description('All time')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->color('success')
                ->chart([40, 55, 45, 60, 75, 80, 90]),

            Stat::make('Orders This Month', Order::thisMonth()->count())
                ->description('+12% from last month')
                ->color('primary'),
        ];
    }
}
```

## Chart Widget

```php
class OrdersChartWidget extends ChartWidget
{
    protected static ?string $heading = 'Orders Over Time';
    protected static ?int $sort = 2;
    protected static string $color = 'info';

    protected function getData(): array
    {
        $data = Order::selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')->orderBy('date')->get();

        return [
            'datasets' => [['label' => 'Orders', 'data' => $data->pluck('count')]],
            'labels'   => $data->pluck('date'),
        ];
    }

    protected function getType(): string { return 'line'; }
}
```

## Widget Registration
Register widgets in the Filament panel provider, not in the widget class:

```php
// AppServiceProvider or Panel provider
->widgets([RevenueOverviewWidget::class, OrdersChartWidget::class])
```

Or on a specific dashboard page:
```php
protected function getHeaderWidgets(): array
{
    return [RevenueOverviewWidget::class];
}
```

## Dashboard Organization
- Use `$sort` to control widget order
- Group related stats in one `StatsOverviewWidget`
- Keep chart widgets focused — one metric per chart
- Use `->lazy()` on expensive widgets to defer loading
