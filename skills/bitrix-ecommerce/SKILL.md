---
name: bitrix-ecommerce
description: >
  Deep analysis of 1C-Bitrix online store setup. Covers catalog structure, SKU/variants,
  order flow customizations, payment systems, delivery services, 1C sync, and discount logic.
  Trigger on: bitrix ecommerce, битрикс магазин, каталог битрикс, заказы битрикс, интеграция 1с.
user-invokable: true
argument-hint: "[path-to-bitrix-root]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Bitrix E-commerce Deep Analysis

Analyzes the complete e-commerce configuration of a 1C-Bitrix online store.

## E-commerce Architecture in Bitrix

```
┌─────────────────────────────────────────────────────┐
│                    FRONT-END                        │
│  Catalog → Product Page → Cart → Checkout → Thanks  │
│  (Components from sale.* and catalog.* namespace)   │
└───────────────┬─────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────┐
│                   MODULES                           │
│  iblock → catalog → currency → sale                 │
└───────────────┬─────────────────────────────────────┘
                │
┌───────────────▼─────────────────────────────────────┐
│                  DATABASE                           │
│  b_iblock_element (products)                        │
│  b_catalog_price / b_catalog_store_product          │
│  b_sale_basket / b_sale_order / b_sale_order_*      │
└─────────────────────────────────────────────────────┘
```

## Analysis Process

### 1. Catalog Structure

```bash
# Find catalog iblock IDs
grep -rn "IBLOCK_ID\|CATALOG_IBLOCK_ID" /var/www/html/local/ --include="*.php" | \
  grep -v "^Binary\|\.svn\|node_modules" | head -30

# Find SKU/offers setup
grep -rn "OFFERS_IBLOCK_ID\|SKU_IBLOCK_ID\|PRODUCT_IBLOCK_ID" \
  /var/www/html/local/ --include="*.php" | head -20

# Check catalog component configuration
find /var/www/html/local/ -name ".parameters.php" | \
  xargs grep -l "catalog\|IBLOCK_ID" 2>/dev/null
```

### 2. Price Configuration

```bash
# Find price group IDs used in code
grep -rn "CATALOG_GROUP_ID\|PRICE_CODE\|\"BASE\"\|'BASE'" \
  /var/www/html/local/ --include="*.php" | head -20

# Currency setup
grep -rn "CURRENCY\|CCurrency" /var/www/html/local/ --include="*.php" | head -10
```

### 3. Cart and Checkout Customizations

```bash
# Custom basket event handlers
grep -rn "OnBeforeSaleBasketItemAdd\|OnSaleBasketItemSaved\|OnSaleOrderBeforeSaved" \
  /var/www/html/local/ --include="*.php" -l 2>/dev/null

# Custom checkout components
find /var/www/html/local/ -path "*sale.order*" -o -path "*sale.basket*" \
  -o -path "*sale.checkout*" 2>/dev/null | head -20

# Order saved handlers (common for notifications, integrations)
grep -rn "OnSaleOrderSaved\|OnSaleOrderPaid\|OnSaleStatusChange" \
  /var/www/html/local/ --include="*.php" -l 2>/dev/null
```

### 4. Payment Systems

```bash
# Local payment adapters
ls /var/www/html/local/php_interface/include/sale_payment/ 2>/dev/null
ls /var/www/html/bitrix/php_interface/include/sale_payment/ 2>/dev/null

# Payment modules
ls /var/www/html/bitrix/modules/ | grep -Ei "pay|kassa|yoo|tinkoff|sber|rbk|robokassa" 2>/dev/null
ls /var/www/html/local/modules/ | grep -Ei "pay|kassa|yoo|tinkoff|sber" 2>/dev/null
```

### 5. Delivery Services

```bash
# Local delivery handlers
ls /var/www/html/local/php_interface/include/sale_delivery/ 2>/dev/null
ls /var/www/html/bitrix/php_interface/include/sale_delivery/ 2>/dev/null

# Delivery modules
ls /var/www/html/bitrix/modules/ | grep -Ei "cdek|delivery|russianpost|dhl|dpd|boxberry|pickpoint" 2>/dev/null
ls /var/www/html/local/modules/ | grep -Ei "delivery|cdek|russianpost" 2>/dev/null
```

### 6. 1C Integration

```bash
# Check exchange directory
ls /var/www/html/upload/1c_catalog/ 2>/dev/null | head -10
ls /var/www/html/upload/1c_exchange/ 2>/dev/null | head -10

# Find CommerceML customizations
grep -rn "OnSuccessCatalogImport\|OnBeforeCatalogImport\|OnCatalogImport\|SaleImport" \
  /var/www/html/local/ --include="*.php" -l 2>/dev/null

# Check 1C user creation (separate bitrix user for exchange)
grep -rn "1c\|exchange" /var/www/html/local/ --include="*.php" | \
  grep -i "user\|login\|password" | head -10
```

### 7. Discount and Promotion Logic

```bash
# Discount module usage
grep -rn "DiscountManager\|CSaleDiscount\|OnSaleGetContextCoupons\|CouponManager" \
  /var/www/html/local/ --include="*.php" -l 2>/dev/null

# Custom promo logic
grep -rn "coupon\|promo\|discount" /var/www/html/local/ --include="*.php" | \
  grep -v "//\|#\|\*" | head -20
```

### 8. Email Notifications

```bash
# Find mail templates
find /var/www/html/local/ -path "*/mail/*" -name "*.php" 2>/dev/null

# Find mail event handlers
grep -rn "OnBeforeMailSend\|AddMessage2Log.*mail\|CEventMessage" \
  /var/www/html/local/ --include="*.php" -l 2>/dev/null
```

### 9. Order Form Custom Fields

```bash
# Custom person type properties (billing/delivery fields)
grep -rn "PersonType\|PropertyCollection\|OrderPropertyCollection" \
  /var/www/html/local/ --include="*.php" | head -20
```

## Output Format

```
# Bitrix E-commerce Analysis

## E-commerce Health Score: [0-100]

## Catalog
- Products Iblock: ID=[N] [FOUND/NOT DETERMINED]
- SKU/Offers Iblock: ID=[N] [FOUND/NOT CONFIGURED]
- Price groups: [list of found IDs/names]
- Currency: [RUB/USD/etc]
- Stock management: [Yes/No/Unknown]

## Order Flow
- Standard checkout: [Yes/Custom]
- Custom order handlers: [N handlers — list]
- Order events subscribed: [list]
- Email notifications: [Custom templates/Standard/None]

## Payment Systems
| System | Integration type | Status |
[table or NONE CONFIGURED 🔴]

## Delivery Services
| Service | Integration type | Notes |
[table or NONE CONFIGURED 🔴]

## 1C Integration
- Status: [Active/Not configured/Unknown]
- Exchange directory: [/upload/1c_catalog/ - present/absent]
- Last exchange: [date of newest file or Unknown]
- Custom exchange handlers: [list or None]
- Sync scope: [Products/Orders/Both/Unknown]

## Discounts & Promotions
- Discount engine: [Standard Sale module/Custom]
- Coupon support: [Yes/No]
- Custom promo logic: [description or None]

## Issues
🔴 Critical (blocks purchases): [list]
🔴 Missing payment system: [if none configured]
🟡 No 1C sync configured: [if applicable]
🟡 Custom handlers without error handling: [list]
🟢 Well-configured: [list]

## Recommendations
1. [Top e-commerce improvement]
2. [Second priority]
...
```
