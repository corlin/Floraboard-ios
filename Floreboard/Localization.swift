//
//  Localization.swift
//  Floreboard
//
//  Created by AI Assistant.
//

import Combine
import Foundation

enum Language: String, CaseIterable, Identifiable {
  case en = "en"
  case zh = "zh"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .en: return "English"
    case .zh: return "简体中文"
    }
  }
}

class LocalizationManager: ObservableObject {
  static let shared = LocalizationManager()

  @Published var currentLanguage: Language {
    didSet {
      UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
    }
  }

  private init() {
    if let saved = UserDefaults.standard.string(forKey: "app_language"),
      let lang = Language(rawValue: saved)
    {
      self.currentLanguage = lang
    } else {
      // Default to device language if matches, else en
      let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
      self.currentLanguage = deviceLang.contains("zh") ? .zh : .en
    }
  }

  func t(_ key: String, _ args: [String: String] = [:]) -> String {
    let dict = currentLanguage == .zh ? Locales.zh : Locales.en
    var value = dict[key] ?? key

    for (k, v) in args {
      value = value.replacingOccurrences(of: "{{\(k)}}", with: v)
    }

    return value
  }
}

// Helper for easier access in Views
// Usage: Tx.t("key")
struct Tx {
  static func t(_ key: String, _ args: [String: String] = [:]) -> String {
    LocalizationManager.shared.t(key, args)
  }
}

// MARK: - Locales Data

struct Locales {
  static let en: [String: String] = [
    // App
    "app.nav.dashboard": "Dashboard",
    "app.nav.design": "Design",
    "app.nav.history": "History",
    "app.nav.inventory": "Inventory",
    "app.nav.settings": "Settings",
    "login.storeName": "Store Name",
    "login.enter": "Enter Shop",
    "login.brand": "Floreboard",

    // Home
    "home.greeting": "Good morning, {{name}}",
    "home.subtitle": "Today is {{date}}, ready to create beauty?",
    "home.startDesign": "Start Design",
    "home.stats.flowerCount": "{{count}} types",
    "home.stats.totalStock": "Total Stock: {{count}}",
    "home.stats.stockAlert": "Low Stock Alert",
    "home.stats.alertItems": "{{count}} items",
    "home.stats.revenue": "Revenue",
    "home.quickActions.title": "Quick Actions",
    "home.quickActions.addInventory": "Add Inventory",
    "home.quickActions.smartDesign": "Smart Design",
    "home.inspiration.title": "Daily Inspiration",
    "home.stats.inventoryOverview": "Inventory Overview",
    "home.stats.card.lowStock": "Low Stock",
    "home.stats.designCount": "Designs",
    "home.stats.itemCount": "Items",
    "home.recentDesigns.title": "Recent Designs",
    "home.recentDesigns.viewAll": "View All",
    "home.recentDesigns.empty": "No recent designs found",
    "home.quickActions.inspirationTitle": "Floral Insight",
    "home.quickActions.inspirationText": "Beauty is found in harmony.",

    // Design
    "design.title": "New Design",
    "design.tabs.quick": "Quick Mode",
    "design.tabs.pro": "Pro Mode",
    "design.step.scene": "Occasion",
    "design.step.target": "Target",
    "design.step.confirm": "Confirm",

    "design.scene.title": "What is the occasion?",
    "design.scene.muse": "Inspiration",
    "design.scene.visual": "Visual Muse",
    "design.scene.uploadBtn": "Upload Reference Image",
    "design.scene.changeImage": "Change Image",
    "design.scene.clearImage": "Clear Image",

    "design.recipient.title": "Who is it for?",
    "design.style.title": "Preferred Style?",
    "design.budget.title": "Budget (CNY)",

    "design.pro.school.title": "Select School",
    "design.pro.school.select": "Select School...",
    "design.pro.technique.title": "Select Technique",
    "design.pro.technique.select": "Select Technique...",
    "design.pro.proportion.title": "Proportion Rule",
    "design.pro.proportion.select": "Select Rule...",
    "design.pro.season.title": "Seasonality",
    "design.pro.season.select": "Select Season...",

    // Advanced Visual Muse
    "design.vm.options.title": "Advanced Parameters",
    "design.vm.scale": "Scale",
    "design.vm.mood": "Mood",
    "design.vm.form": "Form",
    "design.vm.bg": "Background",
    "design.vm.options.scale.auto": "Auto",
    "design.vm.options.scale.micro": "Micro",
    "design.vm.options.scale.small": "Small",
    "design.vm.options.scale.large": "Large",
    "design.vm.options.mood.auto": "Auto",
    "design.vm.options.mood.romantic": "Romantic",
    "design.vm.options.mood.serene": "Serene",
    "design.vm.options.mood.dramatic": "Dramatic",
    "design.vm.options.form.auto": "Auto",
    "design.vm.options.form.vertical": "Vertical",
    "design.vm.options.form.cascade": "Cascade",
    "design.vm.options.form.organic": "Organic",
    "design.vm.options.bg.auto": "Auto",
    "design.vm.options.bg.minimal": "Minimal",
    "design.vm.options.bg.luxe": "Luxe",
    "design.action.execute": "Execute Plan",
    "design.action.executed": "Plan Executed",
    "design.pro.context.title": "Cultural Context",
    "design.pro.context.placeholder": "e.g., Traditional Tea Ceremony...",

    "design.loading.analyze": "Analyzing Request...",
    "design.loading.technique": "Selecting Technique...",
    "design.loading.match": "Matching Inventory...",
    "design.loading.generate": "Generating Design...",
    "design.loading.dreaming": "Dreaming up visual...",

    "filter.culture.all": "All",
    "filter.culture.japanese": "Japanese",
    "filter.culture.chinese": "Chinese",
    "filter.culture.western": "Western",

    "design.pro.confirm.title": "Confirm Design",

    "design.generate.button": "Generate Design",
    "design.generate.loading": "AI Designer is working...",

    // Result
    "result.title": "Design Result",
    "result.bom.title": "Flower List",
    "result.cost.title": "Estimated Cost",
    "result.steps.title": "Instructions",
    "result.meaning.title": "Symbolism",

    // History
    "history.title": "Design History",
    "history.search": "Search designs...",
    "history.empty": "No designs found",
    "history.empty.desc": "Your saved designs will appear here.",

    // Inventory
    "inventory.title": "Inventory Management",
    "inventory.add": "Add Flower",
    "inventory.list.title": "Current Inventory",
    "inventory.section.details": "Details",
    "inventory.section.stock": "Stock & Pricing",
    "inventory.edit": "Edit Inventory",
    "inventory.form.meaning": "Meaning",
    "inventory.form.culture": "Culture",
    "inventory.form.cultureOptions.western": "Western",
    "inventory.form.cultureOptions.chinese": "Chinese",
    "inventory.form.cultureOptions.japanese": "Japanese",
    "inventory.form.cultureOptions.universal": "Universal",
    "inventory.row.stock": "Stock",
    "inventory.row.used": "Used",
    "inventory.row.margin": "Margin",

    // Enums
    "enum.category.foliage": "Foliage",
    "enum.category.main": "Main Flower",
    "enum.category.filler": "Filler",

    "enum.occasion.wedding": "Wedding",
    "enum.occasion.birthday": "Birthday",
    "enum.occasion.comfort": "Comfort",
    "enum.occasion.home": "Home Decor",
    "enum.occasion.graduation": "Graduation",
    "enum.occasion.opening": "Opening",
    "enum.occasion.apology": "Apology",
    "enum.occasion.valentine": "Valentine's",
    "enum.occasion.mother_day": "Mother's Day",
    "enum.occasion.other": "Other",

    "enum.style.romantic": "Romantic",
    "enum.style.fresh": "Fresh",
    "enum.style.vintage": "Vintage",
    "enum.style.passionate": "Passionate",
    "enum.style.minimalist": "Minimalist",
    "enum.style.wild": "Wild",
    "enum.style.elegant": "Elegant",

    // Professional Data
    "pro.school.japanese_ikenobo.name": "Ikenobo",
    "pro.school.japanese_ohara.name": "Ohara",
    "pro.school.japanese_sogetsu.name": "Sogetsu",
    "pro.school.chinese_literati.name": "Literati",
    "pro.school.chinese_zen.name": "Zen",
    "pro.school.western_biedermeier.name": "Biedermeier",
    "pro.school.western_english.name": "English Garden",
    "pro.school.fusion.name": "Modern Fusion",

    "pro.tech.kenzan.name": "Kenzan",
    "pro.tech.spiral_hand_tied.name": "Spiral Hand-tied",
    "pro.tech.parallel.name": "Parallel",
    "pro.tech.pave.name": "Pavé",
    "pro.tech.cascade.name": "Cascade",
    "pro.tech.oasis.name": "Floral Foam",
    "pro.tech.wiring.name": "Wiring",

    "pro.prop.7_5_3.name": "7:5:3 (Shin-Soe-Tai)",
    "pro.prop.golden_ratio.name": "Golden Ratio (1:1.618)",
    "pro.prop.free.name": "Free Style",

    "pro.season.spring.name": "Spring",
    "pro.season.summer.name": "Summer",
    "pro.season.autumn.name": "Autumn",
    "pro.season.winter.name": "Winter",
    "pro.season.all.name": "Year-Round",

    // Colors
    "color.white": "White",
    "color.red": "Red",
    "color.pink": "Pink",
    "color.yellow": "Yellow",
    "color.purple": "Purple",
    "color.green": "Green",
    "color.blue": "Blue",
    "color.orange": "Orange",
    "color.warm": "Warm",
    "color.cool": "Cool",
    "color.pastel": "Pastel",
    "color.vibrant": "Vibrant",
    "color.monochrome": "Monochrome",
    "color.auto": "Auto",

    "enum.format.bouquet": "Bouquet",
    "enum.format.vase": "Vase Arrangement",
    "enum.format.box": "Flower Box",
    "enum.format.basket": "Basket",

    // General
    "general.save": "Save",
    "general.cancel": "Cancel",
    "general.done": "Done",
    "general.search": "Search",
    "general.delete": "Delete",
    "general.error": "Error",
    "general.ok": "OK",
    "inventory.list.empty.title": "No flowers found",

    // Errors
    "error.missingApiKey": "API Key is missing. Please configure it in Settings.",
    "error.invalidURL": "Invalid API Endpoint URL.",
    "error.apiError": "API Request failed with status code: {{code}}",
    "error.imageEncodingFailed": "Failed to process image.",
    "error.saveImage": "Failed to save image to disk",
    "error.invalidImageData": "Invalid image data received",

    "inventory.form.color": "Color",
    "inventory.form.stock": "Stock",
    "inventory.form.cost": "Cost",
    "inventory.form.retail": "Retail",
    "inventory.form.submit": "Add Flower",
    "inventory.form.name": "Name",
    "inventory.form.category": "Category",

    // Settings
    "settings.title": "Settings",
    "settings.language": "Language",
    "settings.account": "Account",
    "settings.storeName": "Store Name",
    "settings.logout": "Logout",
    "settings.apiProvider": "API Provider",
    "settings.provider": "Provider",
    "settings.apiKey": "API Key",
    "settings.endpoint": "Endpoint",
    "settings.textModel": "Text Model (Chat)",
    "settings.api.model": "Model",
    "settings.modelName": "Model Name",
    "settings.visionModel": "Vision Model",
    "settings.imageModel": "Image Generation",
    "settings.imageEndpoint": "Image Endpoint",
    "settings.businessRules": "Business Rules",
    "settings.defaultBudget": "Default Budget (¥)",
    "settings.lowStockWarning": "Low Stock Warning",
    "settings.saveConfig": "Save Configuration",
  ]

  static let zh: [String: String] = [
    // App
    "app.nav.dashboard": "仪表盘",
    "app.nav.design": "花艺创作",
    "app.nav.history": "历史方案",
    "app.nav.inventory": "库存管理",
    "app.nav.settings": "系统设置",
    "login.storeName": "店铺名称",
    "login.enter": "进入店铺",
    "login.brand": "Floreboard",

    // Home
    "home.greeting": "早安，{{name}}",
    "home.subtitle": "今天是 {{date}}，准备好创造美了吗？",
    "home.startDesign": "开始新设计",
    "home.stats.flowerCount": "{{count}} 种花材",
    "home.stats.totalStock": "总库存 {{count}} 枝",
    "home.stats.stockAlert": "库存预警",
    "home.stats.alertItems": "{{count}} 项",
    "home.stats.revenue": "累计创收",
    "home.quickActions.title": "快捷操作",
    "home.quickActions.addInventory": "花材入库",
    "home.quickActions.smartDesign": "智能设计",
    "home.inspiration.title": "今日灵感",
    "home.stats.inventoryOverview": "库存概览",
    "home.stats.card.lowStock": "库存不足",
    "home.stats.designCount": "个方案",
    "home.stats.itemCount": "件商品",
    "home.recentDesigns.title": "最近设计",
    "home.recentDesigns.viewAll": "查看全部",
    "home.recentDesigns.empty": "暂无设计记录",
    "home.quickActions.inspirationTitle": "花艺洞察",
    "home.quickActions.inspirationText": "和谐是美的灵魂。",

    // Design
    "design.title": "定制设计",
    "design.tabs.quick": "快捷模式",
    "design.tabs.pro": "专业模式",
    "design.step.scene": "选择场景",
    "design.step.target": "对象风格",
    "design.step.confirm": "确认生成",

    "design.scene.title": "主要的赠送场景是？",
    "design.scene.muse": "场景灵感",
    "design.scene.visual": "以图生花",
    "design.scene.uploadBtn": "上传灵感参考图",
    "design.scene.changeImage": "更换图片",
    "design.scene.clearImage": "清除图片",

    "design.recipient.title": "赠送对象是？",
    "design.style.title": "偏好的风格？",
    "design.budget.title": "预算范围 (元)",

    "design.pro.school.title": "选择花艺流派",
    "design.pro.school.select": "选择流派...",
    "design.pro.technique.title": "选择技法",
    "design.pro.technique.select": "选择技法...",
    "design.pro.proportion.title": "比例规则",
    "design.pro.proportion.select": "选择规则...",
    "design.pro.season.title": "季节美学",
    "design.pro.season.select": "选择季节...",

    // Advanced Visual Muse
    "design.vm.options.title": "高级参数",
    "design.vm.scale": "作品规模",
    "design.vm.mood": "情感基调",
    "design.vm.form": "构图形式",
    "design.vm.bg": "背景风格",
    "design.vm.options.scale.auto": "自动",
    "design.vm.options.scale.micro": "微型",
    "design.vm.options.scale.small": "小型",
    "design.vm.options.scale.large": "大型",
    "design.vm.options.mood.auto": "自动",
    "design.vm.options.mood.romantic": "浪漫",
    "design.vm.options.mood.serene": "宁静",
    "design.vm.options.mood.dramatic": "戏剧性",
    "design.vm.options.form.auto": "自动",
    "design.vm.options.form.vertical": "垂直",
    "design.vm.options.form.cascade": "瀑布",
    "design.vm.options.form.organic": "自然",
    "design.vm.options.bg.auto": "自动",
    "design.vm.options.bg.minimal": "极简",
    "design.vm.options.bg.luxe": "奢华",
    "design.action.execute": "执行方案",
    "design.action.executed": "方案已执行",
    "design.pro.context.title": "文化语境",
    "design.pro.context.placeholder": "例如：传统茶道...",

    "design.loading.analyze": "正在分析需求...",
    "design.loading.technique": "选择最佳技法...",
    "design.loading.match": "匹配库存花材...",
    "design.loading.generate": "生成最终方案...",
    "design.loading.dreaming": "正在构想效果图...",

    "filter.culture.all": "全部",
    "filter.culture.japanese": "日式",
    "filter.culture.chinese": "中式",
    "filter.culture.western": "西式",

    "design.pro.confirm.title": "设计确认",

    "design.generate.button": "立即生成",
    "design.generate.loading": "AI 设计师正在工作中...",

    // Result
    "result.title": "设计方案",
    "result.bom.title": "花材清单",
    "result.cost.title": "预估成本",
    "result.steps.title": "制作步骤",
    "result.meaning.title": "设计寓意",

    // History
    "history.title": "设计方案历史",
    "history.search": "搜索方案...",
    "history.empty": "暂无设计记录",
    "history.empty.desc": "您的设计方案将显示在这里。",

    // Inventory
    "inventory.title": "花材库存",
    "inventory.add": "新增入库",
    "inventory.list.title": "当前库存",
    "inventory.section.details": "基本信息",
    "inventory.section.stock": "库存与价格",
    "inventory.edit": "编辑花材",
    "inventory.form.meaning": "花语",
    "inventory.form.culture": "文化属性",
    "inventory.form.cultureOptions.western": "西式",
    "inventory.form.cultureOptions.chinese": "中式",
    "inventory.form.cultureOptions.japanese": "日式",
    "inventory.form.cultureOptions.universal": "通用",
    "inventory.row.stock": "库存",
    "inventory.row.used": "已用",
    "inventory.row.margin": "利润率",

    // Enums
    "enum.category.foliage": "叶材",
    "enum.category.main": "主花",
    "enum.category.filler": "配花",

    "enum.occasion.wedding": "婚礼",
    "enum.occasion.birthday": "生日",
    "enum.occasion.comfort": "慰问",
    "enum.occasion.home": "居家",
    "enum.occasion.graduation": "毕业",
    "enum.occasion.opening": "开业",
    "enum.occasion.apology": "致歉",
    "enum.occasion.valentine": "情人节",
    "enum.occasion.mother_day": "母亲节",
    "enum.occasion.other": "其他",

    "enum.style.romantic": "浪漫",
    "enum.style.fresh": "清新",
    "enum.style.vintage": "复古",
    "enum.style.passionate": "热烈",
    "enum.style.minimalist": "极简",
    "enum.style.wild": "野趣",
    "enum.style.elegant": "高雅",

    // Professional Data
    "pro.school.japanese_ikenobo.name": "池坊",
    "pro.school.japanese_ohara.name": "小原流",
    "pro.school.japanese_sogetsu.name": "草月流",
    "pro.school.chinese_literati.name": "文人花",
    "pro.school.chinese_zen.name": "禅花",
    "pro.school.western_biedermeier.name": "比德迈尔",
    "pro.school.western_english.name": "英式花园",
    "pro.school.fusion.name": "融合创意",

    "pro.tech.kenzan.name": "剑山固定",
    "pro.tech.spiral_hand_tied.name": "螺旋手绑",
    "pro.tech.parallel.name": "平行式",
    "pro.tech.pave.name": "铺面式",
    "pro.tech.cascade.name": "瀑布式",
    "pro.tech.oasis.name": "花泥插制",
    "pro.tech.wiring.name": "铁丝技法",

    "pro.prop.7_5_3.name": "花道 7:5:3",
    "pro.prop.golden_ratio.name": "黄金比例",
    "pro.prop.free.name": "自由比例",

    "pro.season.spring.name": "春",
    "pro.season.summer.name": "夏",
    "pro.season.autumn.name": "秋",
    "pro.season.winter.name": "冬",
    "pro.season.all.name": "四季",

    // Colors
    "color.white": "白色",
    "color.red": "红色",
    "color.pink": "粉色",
    "color.yellow": "黄色",
    "color.purple": "紫色",
    "color.green": "绿色",
    "color.blue": "蓝色",
    "color.orange": "橙色",
    "color.warm": "暖色系",
    "color.cool": "冷色系",
    "color.pastel": "粉嫩系",
    "color.vibrant": "鲜艳系",
    "color.monochrome": "单色系",
    "color.auto": "智能配色",

    "enum.format.bouquet": "花束",
    "enum.format.vase": "瓶插",
    "enum.format.box": "花盒",
    "enum.format.basket": "花篮",

    // General
    "general.save": "保存",
    "general.cancel": "取消",
    "general.done": "完成",
    "general.search": "搜索",
    "general.delete": "删除",
    "general.error": "错误",
    "general.ok": "确定",
    "inventory.list.empty.title": "暂无花材",

    // Errors
    "error.missingApiKey": "未配置 API Key，请前往设置页面配置。",
    "error.invalidURL": "API 接口地址无效。",
    "error.apiError": "API 请求失败，状态码: {{code}}",
    "error.imageEncodingFailed": "图片处理失败。",
    "error.saveImage": "图片保存失败",
    "error.invalidImageData": "无效的图片数据",

    "inventory.form.color": "色系",
    "inventory.form.stock": "库存",
    "inventory.form.cost": "成本",
    "inventory.form.retail": "零售",
    "inventory.form.submit": "确认入库",
    "inventory.form.name": "名称",
    "inventory.form.category": "分类",

    // Settings
    "settings.title": "系统设置",
    "settings.language": "语言 / Language",
    "settings.account": "账户信息",
    "settings.storeName": "店铺名称",
    "settings.logout": "退出登录",
    "settings.apiProvider": "API 服务商",
    "settings.provider": "服务商",
    "settings.apiKey": "API Key",
    "settings.endpoint": "接口地址",
    "settings.textModel": "对话模型",
    "settings.api.model": "模型",
    "settings.modelName": "模型名称",
    "settings.visionModel": "视觉模型",
    "settings.imageModel": "绘图模型",
    "settings.imageEndpoint": "绘图接口",
    "settings.businessRules": "业务规则",
    "settings.defaultBudget": "默认预算 (元)",
    "settings.lowStockWarning": "库存预警阈值",
    "settings.saveConfig": "保存配置",
  ]
}
