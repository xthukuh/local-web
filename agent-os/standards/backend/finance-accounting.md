# Finance & Accounting Patterns (Phoenix Sys)

## Double-Entry Bookkeeping
Every financial transaction posts balanced journal entries:

```php
class JournalService
{
    public function post(Transaction $transaction, array $entries): void
    {
        DB::transaction(function () use ($transaction, $entries): void {
            $totalDebit  = collect($entries)->where('type', 'debit')->sum('amount');
            $totalCredit = collect($entries)->where('type', 'credit')->sum('amount');

            if ($totalDebit !== $totalCredit) {
                throw new UnbalancedJournalException("Debit {$totalDebit} ≠ Credit {$totalCredit}");
            }

            foreach ($entries as $entry) {
                JournalEntry::create([
                    'tenant_id'      => $transaction->tenant_id,
                    'transaction_id' => $transaction->id,
                    'account_id'     => $entry['account_id'],
                    'type'           => $entry['type'], // debit | credit
                    'amount'         => $entry['amount'], // integer minor units
                    'currency'       => $entry['currency'],
                    'rate'           => $entry['rate'] ?? 100000000, // rate * 10^8
                    'description'    => $entry['description'] ?? null,
                ]);
            }
        });
    }
}
```

## Chart of Accounts Categories
```php
enum AccountCategory: string
{
    case Asset     = 'asset';
    case Liability = 'liability';
    case Capital   = 'capital';
    case Revenue   = 'revenue';
    case Expense   = 'expense';
}
```

## Money Storage (CRITICAL)
```
NEVER store monetary values as float/decimal in PHP
ALWAYS store as integer minor units
USD 99.99 → 9999
KES 1,500.00 → 150000
```

Use `brick/money` for all arithmetic:
```php
use Brick\Money\Money;
use Brick\Money\Currency;

$price = Money::ofMinor(9999, 'USD');  // $99.99
$tax   = $price->multipliedBy('0.16', RoundingMode::HALF_UP);
$total = $price->plus($tax);
$stored = $total->getMinorAmount()->toInt(); // store this integer
```

## Multi-Currency Exchange Rates
- Snapshot rate at transaction time — NEVER recompute old transactions with new rates
- Exchange rates stored with 8 decimal precision: `rate decimal(18,8)`
- Always record both `currency` and `exchange_rate` on financial records

```php
class CurrencyService
{
    public function convert(int $amount, string $from, string $to, ?Carbon $asOf = null): int
    {
        $rate = ExchangeRate::forDate($from, $to, $asOf ?? now());
        return (int) round($amount * $rate->rate);
    }

    public function toBaseCurrency(int $amount, string $currency, Business $business): int
    {
        if ($currency === $business->base_currency) return $amount;
        return $this->convert($amount, $currency, $business->base_currency);
    }
}
```

## Transaction Reversal
Never delete transactions — reverse them:
```php
class TransactionService
{
    public function reverse(Transaction $transaction, string $reason): Transaction
    {
        DB::transaction(function () use ($transaction, $reason) {
            $reversal = $transaction->replicate();
            $reversal->type       = 'reversal';
            $reversal->parent_id  = $transaction->id;
            $reversal->notes      = "Reversal: {$reason}";
            $reversal->save();

            // Swap debits and credits
            foreach ($transaction->journalEntries as $entry) {
                $reversal->journalEntries()->create([
                    ...$entry->toArray(),
                    'type' => $entry->type === 'debit' ? 'credit' : 'debit',
                ]);
            }
        });
    }
}
```
