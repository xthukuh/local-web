# Naming Conventions

## PHP / Laravel
- Classes: `PascalCase` — `UserController`, `InvoiceService`, `OrderObserver`
- Methods & variables: `camelCase` — `getActiveUsers()`, `$invoiceTotal`
- Constants: `UPPER_SNAKE_CASE` — `MAX_RETRY_COUNT`
- Database tables: `snake_case` plural — `user_profiles`, `invoice_items`
- Database columns: `snake_case` — `created_at`, `first_name`
- Pivot tables: alphabetical order — `post_tag` (not `tag_post`)

## Laravel Specific
- Controllers: singular noun + Controller — `UserController` (not `UsersController`)
- Models: singular PascalCase — `User`, `InvoiceItem`
- Migrations: descriptive snake_case — `create_users_table`, `add_status_to_orders_table`
- Jobs: verb phrase — `SendWelcomeEmail`, `ProcessPayment`
- Events: past tense — `UserRegistered`, `OrderPlaced`
- Listeners: present tense describing action — `SendWelcomeNotification`, `UpdateInventory`
- Policies: Model name + Policy — `UserPolicy`, `OrderPolicy`
- Form Requests: descriptive + Request — `StoreUserRequest`, `UpdateProfileRequest`

## Filament
- Resources: singular Model name + Resource — `UserResource`, `InvoiceResource`
- Pages: descriptive + page type — `ListUsers`, `CreateUser`, `EditUser`
- Widgets: descriptive + Widget — `RevenueOverviewWidget`, `LatestOrdersWidget`
- Actions: descriptive verb — `ApproveAction`, `ExportToCsvAction`
