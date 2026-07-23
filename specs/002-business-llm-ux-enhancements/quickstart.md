# Quickstart Validation Guide: Feature 002

**Feature Directory**: [specs/002-business-llm-ux-enhancements](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements)  
**Spec**: [spec.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/spec.md)  
**Plan**: [plan.md](file:///Users/corlin/2026/Floraboard-ios/specs/002-business-llm-ux-enhancements/plan.md)  

---

## 🚀 Scenario 1: Order Lifecycle & Automatic Inventory Locking

1. Open Floraboard iOS app.
2. Generate an AI Floral Design or open a design from "Recent Floral Designs".
3. Tap "Convert to Order" -> Select status "Confirmed (锁定库存)".
4. Navigate to **Inventory Tab**:
   - Verify mapped flower quantities are automatically deducted by the ordered amounts.
5. Change Order status to "Delivered (已交付)":
   - Verify order is archived and inventory counts remain accurate.

---

## 🚀 Scenario 2: Purchase Order Text Export

1. Navigate to **Inventory Tab** or open **Inventory Analytics Sheet**.
2. Tap "Export Purchase Order (导出采购单)".
3. Verify native iOS `UIActivityViewController` share sheet appears.
4. Select "Copy":
   - Paste clipboard text in Notes or WeChat.
   - Verify text includes formatted header, low stock item names, missing quantities, and supplier restocking note.

---

## 🚀 Scenario 3: AI Typing Effect Streaming & Image Preprocessing

1. Navigate to **Design Tab** -> Select Visual Muse.
2. Select a high-resolution reference photo (>5MB).
3. Observe background image compressor scales image to <500KB before uploading to proxy.
4. Tap "Generate AI Plan":
   - Observe Skeleton Shimmer placeholders with progressive status badges (`[1/3] Palette...`).
   - Observe AI design description typing effect rendering text incrementally.

---

## 🚀 Scenario 4: Skeleton Shimmer & Motion Rubber-banding

1. Trigger AI generation or image loading.
2. Observe smooth gradient shimmer animation sweeping across glassmorphic cards.
3. Open any high-resolution image preview (`ZoomableImageView`).
4. Drag image beyond boundary and release:
   - Observe smooth rubber-banding spring return physics without abrupt clipping.
