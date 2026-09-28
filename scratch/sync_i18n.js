#!/usr/bin/env node

/**
 * sync_i18n.js
 *
 * Extracts Web's 5 locale dictionaries (zh-CN, en-US, ja-JP, ko-KR, fr-FR)
 * and merges them with Floreboard/Localizable.xcstrings, ensuring complete
 * 5-language coverage (zh-Hans, en, ja, ko, fr) for both Web and iOS-specific keys.
 */

const fs = require('fs');
const path = require('path');

// 1. Path definitions
const ROOT_DIR = path.resolve(__dirname, '..');
const XSTRINGS_PATH = path.join(ROOT_DIR, 'Floreboard', 'Localizable.xcstrings');

const WEB_LOCALES_DIR = fs.existsSync(path.join(__dirname, 'web_locales'))
  ? path.join(__dirname, 'web_locales')
  : '/Users/corlin/2026/floreboard-web/src/i18n/locales';

const LOCALE_FILE_MAP = {
  'zh-Hans': 'zh-CN.json',
  'en': 'en-US.json',
  'ja': 'ja-JP.json',
  'ko': 'ko-KR.json',
  'fr': 'fr-FR.json'
};

const ALL_LANGUAGES = ['zh-Hans', 'en', 'ja', 'ko', 'fr'];

// Helper to flatten nested JSON objects to dot-separated keys
function flattenObject(obj, prefix = '') {
  let result = {};
  for (const [key, value] of Object.entries(obj)) {
    const newKey = prefix ? `${prefix}.${key}` : key;
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      Object.assign(result, flattenObject(value, newKey));
    } else {
      result[newKey] = String(value);
    }
  }
  return result;
}

// 2. Web fallbacks for keys present in zh-CN / en-US but missing in ja-JP, ko-KR, fr-FR
const WEB_FALLBACKS = {
  'app.tenant.search': {
    ja: '店舗を検索...',
    ko: '매장 검색...',
    fr: 'Rechercher une boutique...'
  },
  'app.tenant.myShops': {
    ja: 'マイショップ',
    ko: '내 매장',
    fr: 'Mes boutiques'
  },
  'app.tenant.create': {
    ja: '新しい店舗を作成',
    ko: '새 매장 만들기',
    fr: 'Créer une nouvelle boutique'
  },
  'app.tenant.notFound': {
    ja: '関連する店舗が見つかりません',
    ko: '관련 매장을 찾을 수 없습니다',
    fr: 'Aucune boutique trouvée'
  },
  'onboarding.title': {
    ja: 'フラワーショップに名前を付けましょう',
    ko: '꽃집 이름을 정해주세요',
    fr: 'Nommez votre boutique de fleurs'
  },
  'onboarding.subtitle': {
    ja: 'デジタルワークスペースの初期設定を開始しましょう',
    ko: '디지털 워크스페이스 설정을 시작합니다',
    fr: 'Commençons à configurer votre espace de travail'
  },
  'onboarding.shopName': {
    ja: '店舗名',
    ko: '매장 이름',
    fr: 'Nom de la boutique'
  },
  'onboarding.placeholder': {
    ja: '例：花様年華',
    ko: '예: 꽃피는 봄날',
    fr: 'Ex: Fleur & Poésie'
  },
  'onboarding.submit': {
    ja: 'ワークスペースを作成',
    ko: '워크스페이스 만들기',
    fr: 'Créer l\'espace de travail'
  },
  'onboarding.cancel': {
    ja: 'キャンセル',
    ko: '취소',
    fr: 'Annuler'
  },
  'onboarding.success': {
    ja: '店舗を作成しました！',
    ko: '매장이 성공적으로 생성되었습니다!',
    fr: 'Boutique créée avec succès !'
  },
  'onboarding.error': {
    ja: '店舗の作成に失敗しました',
    ko: '매장 생성에 실패했습니다',
    fr: 'Échec de la création de la boutique'
  },
  'settings.subscription.title': {
    ja: '会員プラン＆クレジットセンター',
    ko: '회원 멤버십 & 크레딧 센터',
    fr: 'Abonnements et Centre de Crédits'
  },
  'settings.subscription.subtitle': {
    ja: 'Cloudflare グローバルエッジと Waffo 統合決済を採用、超高速なAI生成と4Kレンダリングを実現',
    ko: 'Cloudflare 글로벌 엣지 및 Waffo 통합 결제 기반, 초고속 AI 생성과 4K 렌더링 지원',
    fr: 'Propulsé par Cloudflare Global Edge et paiements Waffo pour une génération IA rapide et rendus 4K'
  },
  'settings.subscription.creditsBalance': {
    ja: '現在の利用可能クレジット',
    ko: '현재 사용 가능한 크레딧',
    fr: 'Crédits disponibles actuels'
  },
  'settings.subscription.points': {
    ja: 'ポイント',
    ko: '포인트',
    fr: 'pts'
  },
  'settings.subscription.tier': {
    ja: '会員ランク',
    ko: '회원 등급',
    fr: 'Niveau d\'adhésion'
  },
  'settings.subscription.free': {
    ja: '無料体験版',
    ko: '무료 체험',
    fr: 'Version gratuite'
  },
  'settings.subscription.pro': {
    ja: 'Pro 会員',
    ko: 'Pro 프로 회원',
    fr: 'Membre Pro'
  },
  'settings.subscription.enterprise': {
    ja: 'ビジネス会員',
    ko: '엔터프라이즈',
    fr: 'Entreprise'
  },
  'settings.subscription.validUntil': {
    ja: '有効期限',
    ko: '유효 기간',
    fr: 'Valable jusqu\'au'
  },
  'settings.subscription.refresh': {
    ja: 'クレジットを更新',
    ko: '크레딧 새로고침',
    fr: 'Actualiser les crédits'
  },
  'settings.subscription.rulesTitle': {
    ja: 'クレジット消費ルール',
    ko: '크레딧 차감 규칙',
    fr: 'Règles de consommation des crédits'
  },
  'settings.subscription.ruleText': {
    ja: 'AIフラワーデザイン / 画像解析：1 回 1 クレジット',
    ko: 'AI 꽃꽂이 디자인 / 꽃 인식: 1회당 1 크레딧',
    fr: 'Design Floral IA / Reconnaissance: 1 crédit / requête'
  },
  'settings.subscription.ruleImage': {
    ja: '高解像度 4K レンダリング出図：1 回 5 クレジット',
    ko: '고화질 4K 상업 렌더링: 1회당 5 크레딧',
    fr: 'Rendu commercial 4K haute résolution: 5 crédits / image'
  },
  'settings.subscription.ruleEdge': {
    ja: 'Cloudflare グローバルエッジ直結、超高速レスポンス',
    ko: 'Cloudflare 글로벌 엣지 직결, 초고속 응답',
    fr: 'Connexion directe Cloudflare Global Edge, réponse ultra-rapide'
  },
  'settings.subscription.plansTitle': {
    ja: '会員アップグレード＆クレジットチャージ',
    ko: '멤버십 업그레이드 및 크레딧 충전',
    fr: 'Formules d\'adhésion et Recharges de Crédits'
  },
  'settings.subscription.popular': {
    ja: 'おすすめ',
    ko: '인기 추천',
    fr: 'Recommandé'
  },
  'settings.subscription.subscribe': {
    ja: '今すぐ登録',
    ko: '지금 가입',
    fr: 'S\'abonner'
  },
  'settings.subscription.buyPack': {
    ja: '今すぐ購入',
    ko: '지금 구매',
    fr: 'Acheter le pack'
  },
  'settings.subscription.processing': {
    ja: '安全な決済ページを呼び出しています...',
    ko: '보안 결제창을 불러오는 중...',
    fr: 'Ouverture du paiement sécurisé...'
  },
  'settings.subscription.transactionsTitle': {
    ja: 'クレジット利用履歴',
    ko: '크레딧 입출 내역',
    fr: 'Historique des transactions de crédits'
  },
  'settings.subscription.historyEmpty': {
    ja: 'クレジット履歴はありません',
    ko: '크레딧 내역이 없습니다',
    fr: 'Aucune transaction pour le moment'
  },
  'settings.subscription.openCheckout': {
    ja: '決済レジを開きました',
    ko: '결제창이 열렸습니다',
    fr: 'Paiement Waffo ouvert'
  },
  'settings.subscription.paymentSuccessTip': {
    ja: '支払い完了後、更新ボタンを押して最新クレジットを反映してください',
    ko: '결제 완료 후 새로고침을 눌러 최신 크레딧을 동기화하세요',
    fr: 'Après le paiement, veuillez actualiser pour synchroniser votre solde'
  },
  'settings.region.options.cloudflare.name': {
    ja: 'Cloudflare エッジノード',
    ko: 'Cloudflare 엣지 노드',
    fr: 'Nœud Cloudflare Edge'
  },
  'settings.region.options.cloudflare.desc': {
    ja: 'Cloudflare Workers & D1 グローバルエッジコンピューティング、超高速レスポンス',
    ko: 'Cloudflare Workers & D1 글로벌 엣지 컴퓨팅, 초고속 응답',
    fr: 'Cloudflare Workers & D1 Edge global, vitesse ultra-rapide'
  }
};

// 3. Complete iOS-specific translations across all 5 languages
const IOS_TRANSLATIONS = {
  // Paywall
  'paywall.title': {
    'zh-Hans': '升级会员与点数充值',
    'en': 'Upgrade Membership & Credits',
    'ja': '会員アップグレード＆クレジットチャージ',
    'ko': '멤버십 업그레이드 및 크레딧 충전',
    'fr': 'Mise à niveau et Recharges de Crédits'
  },
  'paywall.subtitle': {
    'zh-Hans': '尊享大模型极速方案设计与 4K 商业效果图渲染',
    'en': 'Unlock lightning AI design generation & 4K commercial renders',
    'ja': '超高速AI花芸デザインと4K商業レンダリングを体験',
    'ko': '초고속 AI 디자인 생성 및 4K 상업용 렌더링 혜택',
    'fr': 'Profitez de la génération IA ultra-rapide et de rendus 4K commerciaux'
  },
  'paywall.skip': {
    'zh-Hans': '稍后再说',
    'en': 'Maybe Later',
    'ja': '後で',
    'ko': '나중에 하기',
    'fr': 'Plus tard'
  },
  'paywall.currentCredits': {
    'zh-Hans': '当前剩余点数:',
    'en': 'Current Credits:',
    'ja': '現在の残高:',
    'ko': '현재 보유 크레딧:',
    'fr': 'Crédits restants :'
  },
  'paywall.proBadge': {
    'zh-Hans': 'PRO 会员',
    'en': 'PRO Member',
    'ja': 'PRO 会員',
    'ko': 'PRO 멤버',
    'fr': 'Membre PRO'
  },
  'paywall.later': {
    'zh-Hans': '稍后再说',
    'en': 'Maybe Later',
    'ja': '後で',
    'ko': '나중에 하기',
    'fr': 'Plus tard'
  },
  'paywall.proYearly': {
    'zh-Hans': 'Pro 专业版年卡',
    'en': 'Pro Annual Membership',
    'ja': 'Pro 年間メンバーシップ',
    'ko': 'Pro 연간 멤버십',
    'fr': 'Abonnement Annuel Pro'
  },
  'paywall.save25': {
    'zh-Hans': '立省 25%',
    'en': 'Save 25%',
    'ja': '25%お得',
    'ko': '25% 절약',
    'fr': '-25% Économie'
  },
  'paywall.proYearlyDesc': {
    'zh-Hans': '全年 4000 点数，折合 $7.4/月，点数跨周期滚动',
    'en': '4,000 credits/yr ($7.4/mo), rollover unused credits',
    'ja': '年間4000クレジット（月額換算$7.4）、繰り越し可能',
    'ko': '연간 4000 크레딧(월 $7.4 상당), 미사용 크레딧 이월',
    'fr': '4 000 crédits/an (soit 7,4 $/mois), report des crédits non utilisés'
  },
  'paywall.proMonthly': {
    'zh-Hans': 'Pro 专业版月卡',
    'en': 'Pro Monthly Membership',
    'ja': 'Pro 月額メンバーシップ',
    'ko': 'Pro 월간 멤버십',
    'fr': 'Abonnement Mensuel Pro'
  },
  'paywall.popular': {
    'zh-Hans': '热门推荐',
    'en': 'Popular',
    'ja': '人気',
    'ko': '인기 추천',
    'fr': 'Populaire'
  },
  'paywall.proMonthlyDesc': {
    'zh-Hans': '每月自动注入 300 点数，解锁高峰期优先生成',
    'en': '300 credits injected monthly, priority peak generation',
    'ja': '毎月300クレジット自動付与、混雑時も優先生成',
    'ko': '매월 300 크레딧 자동 지급, 피크 시간대 우선 생성',
    'fr': '300 crédits injectés par mois, génération prioritaire en période de pointe'
  },
  'paywall.pack100': {
    'zh-Hans': '100 点数加油包',
    'en': '100 Credits Booster Pack',
    'ja': '100 クレジットパック',
    'ko': '100 크레딧 부스터팩',
    'fr': 'Pack Booster 100 Crédits'
  },
  'paywall.pack100Desc': {
    'zh-Hans': '100 点永久有效，支持约 100 套方案生成',
    'en': 'Never expires, yields ~100 design generations',
    'ja': '有効期限なし、約100回のデザイン生成に対応',
    'ko': '유효기간 없음, 약 100회 디자인 생성 지원',
    'fr': 'Valable à vie, permet environ 100 générations'
  },
  'paywall.pack300': {
    'zh-Hans': '300 点数进阶包',
    'en': '300 Credits Growth Pack',
    'ja': '300 クレジットパック',
    'ko': '300 크레딧 성장팩',
    'fr': 'Pack Évolution 300 Crédits'
  },
  'paywall.bestValue': {
    'zh-Hans': '超值首选',
    'en': 'Best Value',
    'ja': '一番お得',
    'ko': '최고의 가치',
    'fr': 'Meilleure Offre'
  },
  'paywall.pack300Desc': {
    'zh-Hans': '300 点永久有效，高频设计与旺季首选',
    'en': 'Never expires, ideal for peak season & frequent designs',
    'ja': '有効期限なし、繁忙期や高頻度デザインに最適',
    'ko': '유효기간 없음, 성수기 및 빈번한 디자인에 최적',
    'fr': 'Valable à vie, idéal pour les périodes d\'activité intense'
  },
  'paywall.creditsBadge': {
    'zh-Hans': '+{{count}} 点数',
    'en': '+{{count}} Credits',
    'ja': '+{{count}} クレジット',
    'ko': '+{{count}} 크레딧',
    'fr': '+{{count}} Crédits'
  },
  'paywall.priceYearly': {
    'zh-Hans': '$89.00/年',
    'en': '$89.00/yr',
    'ja': '$89.00/年',
    'ko': '$89.00/년',
    'fr': '89,00 $/an'
  },
  'paywall.priceMonthly': {
    'zh-Hans': '$9.90/月',
    'en': '$9.90/mo',
    'ja': '$9.90/月',
    'ko': '$9.90/월',
    'fr': '9,90 $/mois'
  },
  'paywall.status.uncompleted': {
    'zh-Hans': '购买未完成: {{error}}',
    'en': 'Purchase not completed: {{error}}',
    'ja': '購入が完了していません: {{error}}',
    'ko': '구매가 완료되지 않았습니다: {{error}}',
    'fr': 'Achat non finalisé : {{error}}'
  },
  'paywall.status.failed': {
    'zh-Hans': '处理失败: {{error}}',
    'en': 'Processing failed: {{error}}',
    'ja': '処理に失敗しました: {{error}}',
    'ko': '처리에 실패했습니다: {{error}}',
    'fr': 'Échec du traitement : {{error}}'
  },
  'home.stats.stockUnit': {
    'zh-Hans': '枝在库',
    'en': 'stems in stock',
    'ja': '本在庫',
    'ko': '송이 재고',
    'fr': 'tiges en stock'
  },
  'home.stats.shortageUnit': {
    'zh-Hans': '种紧缺',
    'en': 'low stock',
    'ja': '種不足',
    'ko': '종 부족',
    'fr': 'en rupture'
  },
  'home.stats.revenueTitle': {
    'zh-Hans': '总营收',
    'en': 'Revenue',
    'ja': '総売上',
    'ko': '총매출',
    'fr': 'Chiffre d\'affaires'
  },
  'home.stats.stemsSelected': {
    'zh-Hans': '{{count}} 枝精选',
    'en': '{{count}} stems selected',
    'ja': '{{count}} 本厳選',
    'ko': '{{count}} 송이 엄선',
    'fr': '{{count}} tiges sélectionnées'
  },
  'design.costBadge': {
    'zh-Hans': '({{points}}点)',
    'en': '({{points}} pt)',
    'ja': '({{points}}pt)',
    'ko': '({{points}}크레딧)',
    'fr': '({{points}} pt)'
  },
  'inventory.category.primary': {
    'zh-Hans': '主花',
    'en': 'Main Flower',
    'ja': '主花',
    'ko': '주요 꽃',
    'fr': 'Fleur principale'
  },
  'inventory.category.secondary': {
    'zh-Hans': '配花',
    'en': 'Secondary Flower',
    'ja': '配花',
    'ko': '보조 꽃',
    'fr': 'Fleur secondaire'
  },
  'inventory.category.foliage': {
    'zh-Hans': '叶材',
    'en': 'Foliage',
    'ja': '葉材',
    'ko': '소재(잎)',
    'fr': 'Feuillage'
  },
  'order.originalImage': {
    'zh-Hans': '原图',
    'en': 'Original Image',
    'ja': '元画像',
    'ko': '원본 이미지',
    'fr': 'Image originale'
  },
  'order.customFloral': {
    'zh-Hans': '定制花艺',
    'en': 'Custom Floral',
    'ja': 'オーダーメイド花芸',
    'ko': '맞춤 플로럴',
    'fr': 'Art floral personnalisé'
  },
  'paywall.feature1.title': {
    'zh-Hans': 'AI 花艺大师方案',
    'en': 'AI Floral Design',
    'ja': 'AI 花芸マスタープラン',
    'ko': 'AI 플로럴 마스터 플랜',
    'fr': 'Design Floral IA de Maître'
  },
  'paywall.feature1.subtitle': {
    'zh-Hans': '即时生成专属客户方案与花语',
    'en': 'Instant custom floral plans & meanings',
    'ja': '顧客向けプランと花言葉を即時生成',
    'ko': '맞춤형 제안서와 꽃말 즉시 생성',
    'fr': 'Plans floraux sur mesure et langage des fleurs instantanés'
  },
  'paywall.feature2.title': {
    'zh-Hans': '以图生花灵感解析',
    'en': 'Visual Muse',
    'ja': '画像から花へ (インスピレーション)',
    'ko': '이미지로 꽃 만들기 (비주얼 뮤즈)',
    'fr': 'Inspiration Visuelle (Image vers Fleur)'
  },
  'paywall.feature2.subtitle': {
    'zh-Hans': '上传色板或婚纱，秒出定制花艺',
    'en': 'Turn photos & moodboards into arrangements',
    'ja': '写真や色見本からカスタムアレンジを即座に出力',
    'ko': '사진이나 무드보드를 감각적인 꽃꽂이로 변환',
    'fr': 'Transformez photos et palettes en créations florales'
  },
  'paywall.feature3.title': {
    'zh-Hans': '4K 超清商业效果图',
    'en': '4K Commercial Render',
    'ja': '4K 超高解像度 商業イメージ図',
    'ko': '4K 초고화질 상업 렌더링',
    'fr': 'Rendu Commercial Ultra-HD 4K'
  },
  'paywall.feature3.subtitle': {
    'zh-Hans': '支持高精商用展示与客户提案',
    'en': 'High-res rendering for customer presentations',
    'ja': '高精細な商用プレゼンと顧客提案に対応',
    'ko': '고해상도 고객 프레젠테이션 및 제안 지원',
    'fr': 'Rendus haute résolution pour présentations clients'
  },
  'paywall.plan.pro_yearly.name': {
    'zh-Hans': 'Pro 专业版年卡',
    'en': 'Pro Annual Membership',
    'ja': 'Pro 年間メンバーシップ',
    'ko': 'Pro 연간 멤버십',
    'fr': 'Abonnement Annuel Pro'
  },
  'paywall.plan.pro_yearly.badge': {
    'zh-Hans': '立省 25%',
    'en': 'Save 25%',
    'ja': '25%お得',
    'ko': '25% 절약',
    'fr': '-25% Économie'
  },
  'paywall.plan.pro_yearly.desc': {
    'zh-Hans': '全年 4000 点数，折合 $7.4/月，点数跨周期滚动',
    'en': '4,000 credits/yr ($7.4/mo), rollover unused credits',
    'ja': '年間4000クレジット（月額換算$7.4）、繰り越し可能',
    'ko': '연간 4000 크레딧(월 $7.4 상당), 미사용 크레딧 이월',
    'fr': '4 000 crédits/an (soit 7,4 $/mois), report des crédits non utilisés'
  },
  'paywall.plan.pro_monthly.name': {
    'zh-Hans': 'Pro 专业版月卡',
    'en': 'Pro Monthly Membership',
    'ja': 'Pro 月額メンバーシップ',
    'ko': 'Pro 월간 멤버십',
    'fr': 'Abonnement Mensuel Pro'
  },
  'paywall.plan.pro_monthly.badge': {
    'zh-Hans': '热门推荐',
    'en': 'Most Popular',
    'ja': '人気 No.1',
    'ko': '인기 추천',
    'fr': 'Le Plus Populaire'
  },
  'paywall.plan.pro_monthly.desc': {
    'zh-Hans': '每月自动注入 300 点数，解锁高峰期优先生成',
    'en': '300 credits/mo, unlock priority AI generation',
    'ja': '毎月300クレジット自動付与、優先AI生成を解放',
    'ko': '매월 300 크레딧 자동 지급, 피크타임 우선 생성 지원',
    'fr': '300 crédits/mois, accès prioritaire à la génération IA'
  },
  'paywall.plan.credit_300.name': {
    'zh-Hans': '300 点数进阶包',
    'en': '300 Credit Booster',
    'ja': '300 クレジットパック',
    'ko': '300 크레딧 부스터팩',
    'fr': 'Pack 300 Crédits'
  },
  'paywall.plan.credit_300.desc': {
    'zh-Hans': '300 点永久有效，高频设计与旺季首选',
    'en': '300 permanent credits for peak florist season',
    'ja': '300クレジット無期限有効、繁忙期におすすめ',
    'ko': '300 크레딧 평생 유효, 성수기 필수 선택',
    'fr': '300 crédits sans expiration, idéal pour les périodes d\'affluence'
  },
  'paywall.plan.credit_100.name': {
    'zh-Hans': '100 点数加油包',
    'en': '100 Credit Starter Pack',
    'ja': '100 クレジットパック',
    'ko': '100 크레딧 충전팩',
    'fr': 'Pack 100 Crédits'
  },
  'paywall.plan.credit_100.desc': {
    'zh-Hans': '100 点永久有效，支持约 100 套方案生成',
    'en': '100 permanent credits, approx. 100 designs',
    'ja': '100クレジット無期限有効、約100案生成可能',
    'ko': '100 크레딧 평생 유효, 약 100개 플랜 생성 가능',
    'fr': '100 crédits sans expiration, environ 100 propositions de design'
  },
  'paywall.credits.remaining': {
    'zh-Hans': '当前剩余点数:',
    'en': 'Remaining Credits:',
    'ja': '現在の残高:',
    'ko': '현재 보유 크레딧:',
    'fr': 'Crédits restants :'
  },
  'paywall.credits.pro_badge': {
    'zh-Hans': 'PRO 会员',
    'en': 'PRO Member',
    'ja': 'PRO 会員',
    'ko': 'PRO 회원',
    'fr': 'Membre PRO'
  },
  'paywall.feature.plan_gen': {
    'zh-Hans': '方案生成 1点',
    'en': 'Design 1 pt',
    'ja': 'プラン生成 1点',
    'ko': '플랜 생성 1점',
    'fr': 'Design 1 pt'
  },
  'paywall.feature.vision': {
    'zh-Hans': '多模态 1点',
    'en': 'Vision 1 pt',
    'ja': '画像解析 1点',
    'ko': '이미지 분석 1점',
    'fr': 'Vision 1 pt'
  },
  'paywall.feature.render': {
    'zh-Hans': '4K生图 5点',
    'en': '4K Render 5 pts',
    'ja': '4K画像生成 5点',
    'ko': '4K 렌더링 5점',
    'fr': 'Rendu 4K 5 pts'
  },
  'paywall.status.processing': {
    'zh-Hans': '正在处理购买...',
    'en': 'Processing purchase...',
    'ja': '購入を処理しています...',
    'ko': '구매를 처리 중입니다...',
    'fr': 'Traitement de l\'achat en cours...'
  },
  'paywall.status.success': {
    'zh-Hans': '充值成功！',
    'en': 'Purchase successful!',
    'ja': 'チャージに成功しました！',
    'ko': '충전이 성공적으로 완료되었습니다!',
    'fr': 'Achat effectué avec succès !'
  },
  'paywall.status.updated': {
    'zh-Hans': '充值成功！已更新点数',
    'en': 'Success! Credits updated',
    'ja': '成功しました！クレジットが更新されました',
    'ko': '성공! 크레딧이 업데이트되었습니다',
    'fr': 'Succès ! Crédits mis à jour'
  },

  // Settings Credits Center
  'settings.credits.title': {
    'zh-Hans': '会员与点数中心',
    'en': 'Membership & Credits',
    'ja': '会員プラン＆クレジットセンター',
    'ko': '멤버십 및 크레딧 센터',
    'fr': 'Adhésions et Centre de Crédits'
  },
  'settings.credits.remaining': {
    'zh-Hans': '当前剩余点数',
    'en': 'Available Credits',
    'ja': '現在の利用可能クレジット',
    'ko': '현재 보유 크레딧',
    'fr': 'Crédits disponibles'
  },
  'settings.credits.unit': {
    'zh-Hans': '点',
    'en': 'pts',
    'ja': '点',
    'ko': '포인트',
    'fr': 'pts'
  },
  'settings.credits.tier_free': {
    'zh-Hans': '免费体验',
    'en': 'Free Tier',
    'ja': '無料体験',
    'ko': '무료 체험',
    'fr': 'Essai Gratuit'
  },
  'settings.credits.tier_pro': {
    'zh-Hans': 'PRO 专业版',
    'en': 'Pro Member',
    'ja': 'PRO プロ会員',
    'ko': 'PRO 프로 회원',
    'fr': 'Membre PRO'
  },
  'settings.credits.tier_enterprise': {
    'zh-Hans': '旗舰商户',
    'en': 'Enterprise',
    'ja': 'エンタープライズ',
    'ko': '엔터프라이즈',
    'fr': 'Entreprise'
  },
  'settings.credits.expires_at': {
    'zh-Hans': '到期: {{date}}',
    'en': 'Expires: {{date}}',
    'ja': '有効期限: {{date}}',
    'ko': '만료일: {{date}}',
    'fr': 'Expire le : {{date}}'
  },
  'settings.credits.upgrade_button': {
    'zh-Hans': '充值点数 / 升级会员',
    'en': 'Top Up / Upgrade Membership',
    'ja': 'クレジットチャージ / 会員アップグレード',
    'ko': '크레딧 충전 / 멤버십 업그레이드',
    'fr': 'Recharger / Mettre à niveau'
  },
  'settings.credits.recent_title': {
    'zh-Hans': '近期账单明细',
    'en': 'Recent Transactions',
    'ja': '最近の利用履歴',
    'ko': '최근 이용 내역',
    'fr': 'Dernières transactions'
  },
  'settings.credits.top_up': {
    'zh-Hans': '充值到账',
    'en': 'Top-up Credited',
    'ja': 'チャージ完了',
    'ko': '충전 완료',
    'fr': 'Recharge reçue'
  },
  'settings.credits.consume': {
    'zh-Hans': '点数消耗',
    'en': 'Credit Usage',
    'ja': 'クレジット消費',
    'ko': '크레딧 사용',
    'fr': 'Consommation'
  },
  'settings.credits.empty': {
    'zh-Hans': '暂无点数收支明细',
    'en': 'No transactions yet',
    'ja': '利用履歴はありません',
    'ko': '이용 내역이 없습니다',
    'fr': 'Aucune transaction'
  },
  'settings.currentLanguage': {
    'zh-Hans': '当前语言',
    'en': 'Current Language',
    'ja': '現在の言語',
    'ko': '현재 언어',
    'fr': 'Langue actuelle'
  },

  // Home Stats
  'home.stats.inventoryOverview': {
    'zh-Hans': '库存概览',
    'en': 'Inventory Overview',
    'ja': '在庫概要',
    'ko': '재고 현황',
    'fr': 'Aperçu du Stock'
  },
  'home.stats.flowerCount': {
    'zh-Hans': '%lld 种花材',
    'en': '%lld Varieties',
    'ja': '%lld 種類の花材',
    'ko': '%lld종의 꽃재료',
    'fr': '%lld Variétés de fleurs'
  },
  'home.stats.totalStock': {
    'zh-Hans': '总库存 %lld 枝',
    'en': 'Total %lld Stems',
    'ja': '総在庫 %lld 本',
    'ko': '총 재고 %lld송이',
    'fr': 'Stock Total %lld Tiges'
  },
  'home.stats.stockAlert': {
    'zh-Hans': '库存预警',
    'en': 'Low Stock Alert',
    'ja': '在庫アラート',
    'ko': '재고 경고',
    'fr': 'Alerte de Stock'
  },
  'home.stats.alertItems': {
    'zh-Hans': '%lld 种紧缺',
    'en': '%lld Items Low',
    'ja': '%lld 品目不足',
    'ko': '%lld개 품목 부족',
    'fr': '%lld Articles en Faible Stock'
  },
  'home.stats.revenue': {
    'zh-Hans': '累计创收',
    'en': 'Total Revenue',
    'ja': '累計売上',
    'ko': '누적 수익',
    'fr': 'Revenu Cumulé'
  },
  'home.stats.designCount': {
    'zh-Hans': '共设计 %lld 套',
    'en': '%lld Designs',
    'ja': '合計 %lld デザイン',
    'ko': '총 %lld개 디자인',
    'fr': 'Total %lld Designs'
  },
  'home.stats.itemCount': {
    'zh-Hans': '%lld 项',
    'en': '%lld Items',
    'ja': '%lld 件',
    'ko': '%lld개 항목',
    'fr': '%lld Articles'
  },
  'home.stats.card.lowStock': {
    'zh-Hans': '紧缺品类',
    'en': 'Low Stock',
    'ja': '在庫逼迫',
    'ko': '부족 품목',
    'fr': 'Stock Faible'
  },
  'home.stats.total_revenue': {
    'zh-Hans': '累计营业额',
    'en': 'Total Revenue',
    'ja': '累計売上高',
    'ko': '누적 매출',
    'fr': 'Chiffre d\'Affaires Total'
  },
  'home.stats.today_orders': {
    'zh-Hans': '今日订单',
    'en': 'Today\'s Orders',
    'ja': '本日の注文',
    'ko': '오늘의 주문',
    'fr': 'Commandes du Jour'
  },
  'home.stats.in_production': {
    'zh-Hans': '制作中',
    'en': 'In Production',
    'ja': '制作中',
    'ko': '제작 중',
    'fr': 'En Confection'
  },
  'home.stats.all_settled': {
    'zh-Hans': '全部已清',
    'en': 'All Settled',
    'ja': 'すべて清算済み',
    'ko': '모두 정산됨',
    'fr': 'Tout Réglé'
  },
  'home.lookbook.stems_count': {
    'zh-Hans': '%lld 枝花材',
    'en': '%lld Stems',
    'ja': '%lld 本の花材',
    'ko': '%lld송이의 꽃',
    'fr': '%lld Tiges de fleurs'
  },

  // Analytics
  'analytics.inventory.title': {
    'zh-Hans': '库存概览',
    'en': 'Inventory Analytics',
    'ja': '在庫分析',
    'ko': '재고 분석',
    'fr': 'Analyse des Stocks'
  },
  'analytics.inventory.category_dist': {
    'zh-Hans': '花材类型占比',
    'en': 'Category Distribution',
    'ja': '花材カテゴリー割合',
    'ko': '꽃재료 카테고리 비율',
    'fr': 'Répartition par Catégorie'
  },
  'analytics.inventory.top5': {
    'zh-Hans': '库存排名 Top 5',
    'en': 'Top 5 in Stock',
    'ja': '在庫ランキング Top 5',
    'ko': '재고 순위 Top 5',
    'fr': 'Top 5 en Stock'
  },
  'analytics.inventory.total_value': {
    'zh-Hans': '当前库存总货值',
    'en': 'Total Inventory Value',
    'ja': '現在庫の総資産額',
    'ko': '현재 재고 총 자산가치',
    'fr': 'Valeur Totale du Stock'
  },
  'analytics.revenue.title': {
    'zh-Hans': '营收分析',
    'en': 'Revenue Analytics',
    'ja': '売上分析',
    'ko': '매출 분석',
    'fr': 'Analyse des Revenus'
  },
  'analytics.revenue.total': {
    'zh-Hans': '累计总收入',
    'en': 'Total Revenue',
    'ja': '累計総売上',
    'ko': '누적 총매출',
    'fr': 'Revenu Total'
  },
  'analytics.revenue.avg_margin': {
    'zh-Hans': '平均利润率',
    'en': 'Avg Margin',
    'ja': '平均粗利率',
    'ko': '평균 마진율',
    'fr': 'Marge Moyenne'
  },
  'analytics.revenue.trend': {
    'zh-Hans': '近7日营收走势',
    'en': '7-Day Revenue Trend',
    'ja': '過去7日間の売上推移',
    'ko': '최근 7일 매출 추이',
    'fr': 'Tendance des Revenus sur 7 Jours'
  },
  'analytics.revenue.top3': {
    'zh-Hans': '畅销作品 Top 3',
    'en': 'Top 3 Best Sellers',
    'ja': '売れ筋作品 Top 3',
    'ko': '인기 작품 Top 3',
    'fr': 'Top 3 des Meilleures Ventes'
  },
  'analytics.revenue.no_data': {
    'zh-Hans': '暂无数据',
    'en': 'No data yet',
    'ja': 'データがありません',
    'ko': '데이터 없음',
    'fr': 'Aucune donnée disponible'
  },

  // Craft
  'craft.title': {
    'zh-Hans': '花艺技艺与匠心',
    'en': 'Floral Craft & Artistry',
    'ja': '花芸の技と匠の心',
    'ko': '플로럴 크래프트 & 장인정신',
    'fr': 'Artisanat Floral & Maîtrise'
  },
  'craft.subtitle': {
    'zh-Hans': '遵循花道美学与专业结构',
    'en': 'Rooted in floral aesthetics and structural balance',
    'ja': '生け花美学と専門構造に基づく調和',
    'ko': '화도 미학과 전문적인 구조의 조화',
    'fr': 'Enraciné dans l\'esthétique florale et l\'équilibre structurel'
  },
  'craft.school.title': {
    'zh-Hans': '花艺流派',
    'en': 'Floral Schools',
    'ja': '花芸の流派',
    'ko': '플로럴 유파',
    'fr': 'Écoles Florales'
  },
  'craft.school.desc': {
    'zh-Hans': '东方花道与西方架构的匠心传承',
    'en': 'Heritage of Eastern Ikebana & Western Floral Architecture',
    'ja': '東洋のいけばなと西洋の構築美の継承',
    'ko': '동양의 화도와 서양의 구조적 미학 계승',
    'fr': 'Héritage de l\'Ikebana oriental et de l\'architecture occidentale'
  },
  'craft.technique.title': {
    'zh-Hans': '制作技法',
    'en': 'Craft Techniques',
    'ja': '制作技法',
    'ko': '제작 기법',
    'fr': 'Techniques Artisanales'
  },
  'craft.technique.desc': {
    'zh-Hans': '剑山、螺旋与架构制作指导',
    'en': 'Professional wiring, spiral hand-tie & kenzan mechanics',
    'ja': '剣山留め、スパイラル、構造アレンジの専門指導',
    'ko': '침봉, 스파이럴 핸드타이드 및 구조 제작 가이드',
    'fr': 'Fixation kenzan, spirale à la main et armature florale'
  },
  'craft.proportion.title': {
    'zh-Hans': '美学比例',
    'en': 'Aesthetic Proportions',
    'ja': '美学比率',
    'ko': '미학적 비례',
    'fr': 'Proportions Esthétiques'
  },
  'craft.proportion.desc': {
    'zh-Hans': '7:5:3 花道法则与黄金分割律',
    'en': 'The 7:5:3 Ikebana rule & Golden Ratio geometry',
    'ja': 'いけばな 7:5:3 の法則と黄金比率',
    'ko': '화도 7:5:3 법칙과 황금비율',
    'fr': 'Règle Ikebana 7:5:3 et géométrie du Nombre d\'Or'
  },
  'craft.season.title': {
    'zh-Hans': '节令花信',
    'en': 'Seasonal Harmony',
    'ja': '季節の花信',
    'ko': '계절의 화신(花信)',
    'fr': 'Harmonie Saisonnière'
  },
  'craft.season.desc': {
    'zh-Hans': '顺应四时节气的时令花材调配',
    'en': 'Curated blooms harmonized with natural seasonal cycles',
    'ja': '四季の移ろいに調和する旬の花材選定',
    'ko': '사계절의 흐름에 순응하는 제철 꽃 소재 배합',
    'fr': 'Sélection de fleurs en accord avec le rythme des saisons'
  },
  'craft.guide.title': {
    'zh-Hans': '匠心插花指导',
    'en': 'Master Florist Instructions',
    'ja': '匠の生け花ガイド',
    'ko': '장인의 꽃꽂이 가이드',
    'fr': 'Instructions de Maître Artisan'
  },
  'craft.guide.preparation': {
    'zh-Hans': '花材养护与醒花',
    'en': 'Stem Conditioning & Hydration',
    'ja': '花材の水揚げとお手入れ',
    'ko': '꽃재료 물올림 및 컨디셔닝',
    'fr': 'Hydratation et soin des tiges'
  },
  'craft.guide.arrangement': {
    'zh-Hans': '插制与架构布局',
    'en': 'Structural Framing & Placement',
    'ja': '骨組みと花材配置',
    'ko': '구조 형성 및 꽃 배치',
    'fr': 'Structure et disposition des fleurs'
  },
  'craft.guide.finishing': {
    'zh-Hans': '束扎与养护交付',
    'en': 'Binding, Finishing & Delivery Care',
    'ja': '結束・仕上げと納品管理',
    'ko': '바인딩, 마감 및 배송 관리',
    'fr': 'Ligature, finitions et conseils d\'entretien'
  },

  // Pro Design & Schools
  'design.pro.school.title': {
    'zh-Hans': '花艺流派',
    'en': 'Floral School',
    'ja': '花芸流派',
    'ko': '꽃꽂이 유파',
    'fr': 'École Florale'
  },
  'design.pro.school.select': {
    'zh-Hans': '选择流派',
    'en': 'Select School',
    'ja': '流派を選択',
    'ko': '유파 선택',
    'fr': 'Choisir une École'
  },
  'design.pro.technique.title': {
    'zh-Hans': '制作技法',
    'en': 'Craft Technique',
    'ja': '制作技法',
    'ko': '제작 기법',
    'fr': 'Technique Florale'
  },
  'design.pro.technique.select': {
    'zh-Hans': '选择技法',
    'en': 'Select Technique',
    'ja': '技法を選択',
    'ko': '기법 선택',
    'fr': 'Choisir une Technique'
  },
  'design.pro.proportion.title': {
    'zh-Hans': '比例法则',
    'en': 'Proportion Rule',
    'ja': '比率ルール',
    'ko': '비례 규칙',
    'fr': 'Règle de Proportion'
  },
  'design.pro.proportion.select': {
    'zh-Hans': '选择比例',
    'en': 'Select Proportion',
    'ja': '比率を選択',
    'ko': '비례 선택',
    'fr': 'Choisir une Proportion'
  },
  'design.pro.season.title': {
    'zh-Hans': '季节美学',
    'en': 'Seasonal Aesthetics',
    'ja': '季節の美学',
    'ko': '계절 미학',
    'fr': 'Esthétique Saisonnière'
  },
  'design.pro.season.select': {
    'zh-Hans': '选择季节',
    'en': 'Select Season',
    'ja': '季節を選択',
    'ko': '계절 선택',
    'fr': 'Choisir une Saison'
  },
  'design.pro.context.title': {
    'zh-Hans': '空间与文化语境',
    'en': 'Cultural & Spatial Context',
    'ja': '空間・文化的文脈',
    'ko': '공간 및 문화적 맥락',
    'fr': 'Contexte Spatial & Culturel'
  },
  'design.pro.context.placeholder': {
    'zh-Hans': '例如：高端茶席、禅意茶室、极简画廊',
    'en': 'e.g., Tea ceremony, zen gallery, minimal boutique',
    'ja': '例：茶席、禅の茶室、ミニマルギャラリー',
    'ko': '예: 다도 자리, 선(禪) 다실, 미니멀 갤러리',
    'fr': 'Ex: Cérémonie du thé, galerie zen, boutique minimaliste'
  },
  'design.pro.confirm.title': {
    'zh-Hans': '专业方案确认',
    'en': 'Pro Design Confirmation',
    'ja': 'プロプランの確認',
    'ko': '프로 플랜 확인',
    'fr': 'Confirmation du Plan Pro'
  },

  'pro.school.chinese_literati.name': {
    'zh-Hans': '中国文人花',
    'en': 'Chinese Literati',
    'ja': '文人花',
    'ko': '문인화',
    'fr': 'Fleur de Lettré'
  },
  'pro.school.chinese_zen.name': {
    'zh-Hans': '东方禅花',
    'en': 'Chinese Zen',
    'ja': '禅花',
    'ko': '선화 (禪花)',
    'fr': 'Fleur Zen'
  },
  'pro.school.fusion.name': {
    'zh-Hans': '融合现代',
    'en': 'Fusion Contemporary',
    'ja': 'フュージョン',
    'ko': '퓨전',
    'fr': 'Fusion'
  },
  'pro.school.japanese_ikenobo.name': {
    'zh-Hans': '池坊流',
    'en': 'Ikenobo',
    'ja': '池坊',
    'ko': '이케노보',
    'fr': 'Ikenobo'
  },
  'pro.school.japanese_ohara.name': {
    'zh-Hans': '小原流',
    'en': 'Ohara-ryu',
    'ja': '小原流',
    'ko': '오하라류',
    'fr': 'Ohara'
  },
  'pro.school.japanese_sogetsu.name': {
    'zh-Hans': '草月流',
    'en': 'Sogetsu',
    'ja': '草月流',
    'ko': '소게츠류',
    'fr': 'Sogetsu'
  },
  'pro.school.western_biedermeier.name': {
    'zh-Hans': '比德迈尔',
    'en': 'Biedermeier',
    'ja': 'ビーダーマイヤー',
    'ko': '비더마이어',
    'fr': 'Biedermeier'
  },
  'pro.school.western_english.name': {
    'zh-Hans': '英式花园',
    'en': 'English Garden',
    'ja': 'イングリッシュガーデン',
    'ko': '잉글리시 가든',
    'fr': 'Jardin Anglais'
  },

  'pro.tech.cascade.name': {
    'zh-Hans': '瀑布流坠',
    'en': 'Cascade Style',
    'ja': 'キャスケード',
    'ko': '캐스케이드',
    'fr': 'Cascade'
  },
  'pro.tech.kenzan.name': {
    'zh-Hans': '剑山固定',
    'en': 'Kenzan Pin Holder',
    'ja': '剣山留め',
    'ko': '침봉',
    'fr': 'Kenzan (Pique-fleurs)'
  },
  'pro.tech.oasis.name': {
    'zh-Hans': '花泥插制',
    'en': 'Floral Foam',
    'ja': '吸水スポンジ',
    'ko': '플로럴 폼',
    'fr': 'Mousse Florale (Oasis)'
  },
  'pro.tech.parallel.name': {
    'zh-Hans': '平行架构',
    'en': 'Parallel Arrangement',
    'ja': 'パラレル（平行）',
    'ko': '파라렐 (평행)',
    'fr': 'Parallèle'
  },
  'pro.tech.pave.name': {
    'zh-Hans': '铺面密植',
    'en': 'Pavé Design',
    'ja': 'パヴェ（敷き詰め）',
    'ko': '파붸 (깔기)',
    'fr': 'Pavé'
  },
  'pro.tech.spiral_hand_tied.name': {
    'zh-Hans': '螺旋手绑',
    'en': 'Spiral Hand-tied',
    'ja': 'スパイラル（手組み）',
    'ko': '스파이럴 (핸드타이드)',
    'fr': 'Spirale (Bouquet rond)'
  },
  'pro.tech.wiring.name': {
    'zh-Hans': '铁丝技法',
    'en': 'Wiring & Taping',
    'ja': 'ワイヤリング',
    'ko': '와이어링',
    'fr': 'Montage sur Fil'
  },

  'pro.prop.7_5_3.name': {
    'zh-Hans': '花道 7:5:3',
    'en': 'Ikebana 7:5:3',
    'ja': 'いけばな 7:5:3',
    'ko': '꽃꽂이 7:5:3',
    'fr': 'Ikebana 7:5:3'
  },
  'pro.prop.free.name': {
    'zh-Hans': '自由比例',
    'en': 'Free Proportion',
    'ja': 'フリースタイル',
    'ko': '프리스타일',
    'fr': 'Style Libre'
  },
  'pro.prop.golden_ratio.name': {
    'zh-Hans': '黄金比例',
    'en': 'Golden Ratio',
    'ja': '黄金比',
    'ko': '황금비',
    'fr': 'Nombre d\'Or'
  },

  'pro.season.all.name': {
    'zh-Hans': '🌈 四季通用',
    'en': '🌈 All Seasons',
    'ja': '🌈 四季通年',
    'ko': '🌈 사계절 통년',
    'fr': '🌈 Toutes Saisons'
  },
  'pro.season.autumn.name': {
    'zh-Hans': '🍂 秋实',
    'en': '🍂 Autumn',
    'ja': '🍂 秋',
    'ko': '🍂 가을',
    'fr': '🍂 Automne'
  },
  'pro.season.spring.name': {
    'zh-Hans': '🌸 春生',
    'en': '🌸 Spring',
    'ja': '🌸 春',
    'ko': '🌸 봄',
    'fr': '🌸 Printemps'
  },
  'pro.season.summer.name': {
    'zh-Hans': '🌻 夏繁',
    'en': '🌻 Summer',
    'ja': '🌻 夏',
    'ko': '🌻 여름',
    'fr': '🌻 Été'
  },
  'pro.season.winter.name': {
    'zh-Hans': '❄️ 冬清',
    'en': '❄️ Winter',
    'ja': '❄️ 冬',
    'ko': '❄️ 겨울',
    'fr': '❄️ Hiver'
  },

  // Color Palette
  'color.auto': {
    'zh-Hans': '自由发挥',
    'en': 'AI Decides',
    'ja': 'お任せ',
    'ko': 'AI 추천',
    'fr': 'Laisser l\'IA décider'
  },
  'color.blue': {
    'zh-Hans': '蓝色调',
    'en': 'Blue',
    'ja': 'ブルー系',
    'ko': '블루 톤',
    'fr': 'Bleu'
  },
  'color.cool': {
    'zh-Hans': '冷色调',
    'en': 'Cool Tone',
    'ja': '寒色系',
    'ko': '시원한 색',
    'fr': 'Tons Froids'
  },
  'color.green': {
    'zh-Hans': '绿色调',
    'en': 'Green',
    'ja': 'グリーン系',
    'ko': '그린 톤',
    'fr': 'Vert'
  },
  'color.monochrome': {
    'zh-Hans': '单色调',
    'en': 'Monochrome',
    'ja': 'モノクローム',
    'ko': '모노크롬',
    'fr': 'Monochrome'
  },
  'color.orange': {
    'zh-Hans': '橙色调',
    'en': 'Orange',
    'ja': 'オレンジ系',
    'ko': '오렌지 톤',
    'fr': 'Orange'
  },
  'color.pastel': {
    'zh-Hans': '柔和粉彩',
    'en': 'Pastel Tone',
    'ja': 'パステルカラー',
    'ko': '파스텔 톤',
    'fr': 'Tons Pastel'
  },
  'color.pink': {
    'zh-Hans': '粉色调',
    'en': 'Pink',
    'ja': 'ピンク系',
    'ko': '핑크 톤',
    'fr': 'Rose'
  },
  'color.purple': {
    'zh-Hans': '紫色调',
    'en': 'Purple',
    'ja': 'パープル系',
    'ko': '퍼플 톤',
    'fr': 'Violet'
  },
  'color.red': {
    'zh-Hans': '红色调',
    'en': 'Red',
    'ja': 'レッド系',
    'ko': '레드 톤',
    'fr': 'Rouge'
  },
  'color.vibrant': {
    'zh-Hans': '鲜艳浓烈',
    'en': 'Vibrant Tone',
    'ja': 'ビビッドカラー',
    'ko': '비비드 컬러',
    'fr': 'Tons Vifs'
  },
  'color.warm': {
    'zh-Hans': '暖色调',
    'en': 'Warm Tone',
    'ja': '暖色系',
    'ko': '따뜻한 색',
    'fr': 'Tons Chauds'
  },
  'color.white': {
    'zh-Hans': '白色调',
    'en': 'White',
    'ja': 'ホワイト系',
    'ko': '화이트 톤',
    'fr': 'Blanc'
  },
  'color.yellow': {
    'zh-Hans': '黄色调',
    'en': 'Yellow',
    'ja': 'イエロー系',
    'ko': '옐로우 톤',
    'fr': 'Jaune'
  },

  // Enums
  'enum.category.main': {
    'zh-Hans': '主花',
    'en': 'Main Flower',
    'ja': 'メイン',
    'ko': '메인',
    'fr': 'Fleur Principale'
  },
  'enum.category.filler': {
    'zh-Hans': '配花',
    'en': 'Filler Flower',
    'ja': 'フィラー',
    'ko': '필러',
    'fr': 'Fleur de Remplissage'
  },
  'enum.category.foliage': {
    'zh-Hans': '叶材',
    'en': 'Foliage & Greenery',
    'ja': '葉物',
    'ko': '소재(잎)',
    'fr': 'Feuillage'
  },

  'enum.format.basket': {
    'zh-Hans': '花篮',
    'en': 'Flower Basket',
    'ja': 'バスケット',
    'ko': '꽃바구니',
    'fr': 'Panier Floral'
  },
  'enum.format.bouquet': {
    'zh-Hans': '手捧花束',
    'en': 'Bouquet',
    'ja': 'ブーケ（花束）',
    'ko': '꽃다발',
    'fr': 'Bouquet'
  },
  'enum.format.box': {
    'zh-Hans': '花盒礼盒',
    'en': 'Flower Box',
    'ja': 'フラワーボックス',
    'ko': '플라워 박스',
    'fr': 'Boîte à Fleurs'
  },
  'enum.format.vase': {
    'zh-Hans': '插瓶花艺',
    'en': 'Vase Arrangement',
    'ja': 'アレンジメント（花瓶）',
    'ko': '화병 꽂이',
    'fr': 'Composition en Vase'
  },

  'enum.occasion.apology': {
    'zh-Hans': '致歉与和解',
    'en': 'Apology',
    'ja': 'お詫び・謝罪',
    'ko': '사과 및 화해',
    'fr': 'Excuses'
  },
  'enum.occasion.birthday': {
    'zh-Hans': '生日祝福',
    'en': 'Birthday',
    'ja': '誕生日祝い',
    'ko': '생일 축하',
    'fr': 'Anniversaire'
  },
  'enum.occasion.comfort': {
    'zh-Hans': '慰问与探病',
    'en': 'Get Well & Comfort',
    'ja': 'お見舞い・慰問',
    'ko': '위로 및 문병',
    'fr': 'Rétablissement & Convalescence'
  },
  'enum.occasion.graduation': {
    'zh-Hans': '毕业典礼',
    'en': 'Graduation',
    'ja': '卒業式',
    'ko': '졸업식',
    'fr': 'Remise de Diplôme'
  },
  'enum.occasion.home': {
    'zh-Hans': '居家装饰',
    'en': 'Home Decor',
    'ja': 'インテリア装飾',
    'ko': '홈 데코',
    'fr': 'Décoration Maison'
  },
  'enum.occasion.mother_day': {
    'zh-Hans': '母亲节',
    'en': 'Mother\'s Day',
    'ja': '母の日',
    'ko': '어버이날',
    'fr': 'Fête des Mères'
  },
  'enum.occasion.opening': {
    'zh-Hans': '开业庆典',
    'en': 'Grand Opening',
    'ja': '開店祝い',
    'ko': '개업 축하',
    'fr': 'Ouverture & Inauguration'
  },
  'enum.occasion.other': {
    'zh-Hans': '其他场合',
    'en': 'Other Occasion',
    'ja': 'その他のシーン',
    'ko': '기타 상황',
    'fr': 'Autre Occasion'
  },
  'enum.occasion.valentine': {
    'zh-Hans': '情人节',
    'en': 'Valentine\'s Day',
    'ja': 'バレンタイン',
    'ko': '발렌타인데이',
    'fr': 'Saint-Valentin'
  },
  'enum.occasion.wedding': {
    'zh-Hans': '婚礼与纪念日',
    'en': 'Wedding & Anniversary',
    'ja': '結婚・記念日',
    'ko': '결혼 및 기념일',
    'fr': 'Mariage & Anniversaire'
  },

  'enum.style.elegant': {
    'zh-Hans': '高雅精致',
    'en': 'Elegant',
    'ja': 'エレガント・上品',
    'ko': '엘레강스/고상함',
    'fr': 'Élégant & Raffiné'
  },
  'enum.style.fresh': {
    'zh-Hans': '自然清新',
    'en': 'Fresh & Natural',
    'ja': 'ナチュラル・フレッシュ',
    'ko': '내추럴/프레시',
    'fr': 'Naturel & Frais'
  },
  'enum.style.minimalist': {
    'zh-Hans': '极简线条',
    'en': 'Minimalist',
    'ja': 'ミニマリスト',
    'ko': '미니멀리스트',
    'fr': 'Minimaliste'
  },
  'enum.style.passionate': {
    'zh-Hans': '热烈浓郁',
    'en': 'Passionate',
    'ja': '情熱的・ゴージャス',
    'ko': '열정적/화려함',
    'fr': 'Passionné & Intense'
  },
  'enum.style.romantic': {
    'zh-Hans': '浪漫唯美',
    'en': 'Romantic',
    'ja': 'ロマンチック',
    'ko': '로맨틱',
    'fr': 'Romantique'
  },
  'enum.style.vintage': {
    'zh-Hans': '复古油画',
    'en': 'Vintage',
    'ja': 'ヴィンテージ・油絵風',
    'ko': '빈티지/유화풍',
    'fr': 'Vintage & Peinture à l\'Huile'
  },
  'enum.style.wild': {
    'zh-Hans': '野趣自由',
    'en': 'Wild & Free',
    'ja': 'ワイルド・自然',
    'ko': '와일드/자연',
    'fr': 'Sauvage & Champêtre'
  },

  // Orders
  'order.action.convert': {
    'zh-Hans': '转为正式订单',
    'en': 'Convert to Order',
    'ja': '正式注文に変換',
    'ko': '정식 주문으로 전환',
    'fr': 'Convertir en Commande'
  },
  'order.default_customer': {
    'zh-Hans': '进店散客',
    'en': 'Walk-in Customer',
    'ja': '来店客',
    'ko': '일반 고객',
    'fr': 'Client de Passage'
  },
  'order.detail.items': {
    'zh-Hans': '花材与用量明细',
    'en': 'Items & Materials',
    'ja': '花材・用量明細',
    'ko': '꽃재료 및 사용량 명세',
    'fr': 'Détail des Fleurs et Matériaux'
  },
  'order.detail.title': {
    'zh-Hans': '订单详情',
    'en': 'Order Details',
    'ja': '注文詳細',
    'ko': '주문 상세',
    'fr': 'Détails de la Commande'
  },
  'order.detail.total': {
    'zh-Hans': '合计金额',
    'en': 'Total Amount',
    'ja': '合計金額',
    'ko': '총 금액',
    'fr': 'Montant Total'
  },
  'order.detail.update_status': {
    'zh-Hans': '更新状态',
    'en': 'Update Status',
    'ja': '状態を更新',
    'ko': '상태 업데이트',
    'fr': 'Mettre à Jour le Statut'
  },
  'order.hub.convert_to_order': {
    'zh-Hans': '转为订单',
    'en': 'Create Order',
    'ja': '注文作成',
    'ko': '주문 생성',
    'fr': 'Créer Commande'
  },
  'order.hub.tab.archive': {
    'zh-Hans': '历史归档',
    'en': 'Archived',
    'ja': 'アーカイブ',
    'ko': '보관함',
    'fr': 'Archives'
  },
  'order.hub.tab.orders': {
    'zh-Hans': '实时订单',
    'en': 'Active Orders',
    'ja': '進行中の注文',
    'ko': '진행 중인 주문',
    'fr': 'Commandes en Cours'
  },
  'order.items_count': {
    'zh-Hans': '%lld 种花材',
    'en': '%lld Items',
    'ja': '%lld 種の花材',
    'ko': '%lld종의 꽃재료',
    'fr': '%lld Variétés florales'
  },
  'order.list.empty': {
    'zh-Hans': '暂无进行中订单',
    'en': 'No active orders',
    'ja': '進行中の注文はありません',
    'ko': '진행 중인 주문이 없습니다',
    'fr': 'Aucune commande en cours'
  },
  'order.list.title': {
    'zh-Hans': '花店订单管理',
    'en': 'Order Management',
    'ja': '注文管理',
    'ko': '주문 관리',
    'fr': 'Gestion des Commandes'
  },
  'order.status.draft': {
    'zh-Hans': '草稿',
    'en': 'Draft',
    'ja': '下書き',
    'ko': '임시 저장',
    'fr': 'Brouillon'
  },
  'order.status.quoted': {
    'zh-Hans': '已报价',
    'en': 'Quoted',
    'ja': '見積提出済',
    'ko': '견적 완료',
    'fr': 'Devis Transmis'
  },
  'order.status.confirmed': {
    'zh-Hans': '已确认',
    'en': 'Confirmed',
    'ja': '注文確定',
    'ko': '주문 확정',
    'fr': 'Confirmée'
  },
  'order.status.inProduction': {
    'zh-Hans': '制作中',
    'en': 'In Production',
    'ja': '制作中',
    'ko': '제작 중',
    'fr': 'En Confection'
  },
  'order.status.delivered': {
    'zh-Hans': '已交付',
    'en': 'Delivered',
    'ja': '納品完了',
    'ko': '배송 완료',
    'fr': 'Livrée'
  },
  'order.status.cancelled': {
    'zh-Hans': '已取消',
    'en': 'Cancelled',
    'ja': 'キャンセル済',
    'ko': '취소됨',
    'fr': 'Annulée'
  },

  // Workbench
  'workbench.title': {
    'zh-Hans': '花艺操作台',
    'en': 'Florist Workbench',
    'ja': '花芸ワークベンチ',
    'ko': '플로리스트 작업대',
    'fr': 'Atelier Floral'
  },
  'workbench.subtitle': {
    'zh-Hans': '制作执行与核验清单',
    'en': 'Craft Checklist & Execution',
    'ja': '制作実行・チェックリスト',
    'ko': '제작 실행 및 검수 체크리스트',
    'fr': 'Checklist et Réalisation Florale'
  },
  'workbench.checklist_title': {
    'zh-Hans': '制作核验清单',
    'en': 'Craft Checklist',
    'ja': '制作チェックリスト',
    'ko': '제작 체크리스트',
    'fr': 'Liste de Contrôle'
  },
  'workbench.checklist_hint': {
    'zh-Hans': '制作完成的花材请打勾确认',
    'en': 'Check off flowers as arranged',
    'ja': '配置が完了した花材をチェック',
    'ko': '배치가 완료된 꽃재료를 체크하세요',
    'fr': 'Cochez les fleurs au fur et à mesure'
  },
  'workbench.completed_prompt': {
    'zh-Hans': '作品已制作完成！准备交付吗？',
    'en': 'Arrangement completed! Ready to deliver?',
    'ja': '作品が完成しました！納品の準備はよろしいですか？',
    'ko': '작품 제작이 완료되었습니다! 배송 준비를 하시겠습니까?',
    'fr': 'Composition terminée ! Prêt pour la livraison ?'
  },
  'workbench.customer_label': {
    'zh-Hans': '客户: %@',
    'en': 'Customer: %@',
    'ja': 'お客様: %@',
    'ko': '고객: %@',
    'fr': 'Client : %@'
  },
  'workbench.delivery_time': {
    'zh-Hans': '交付时间: %@',
    'en': 'Delivery: %@',
    'ja': '納品日時: %@',
    'ko': '배송 일시: %@',
    'fr': 'Livraison : %@'
  },
  'workbench.enter_button': {
    'zh-Hans': '进入制作台',
    'en': 'Enter Workbench',
    'ja': 'ワークベンチを開く',
    'ko': '작업대 열기',
    'fr': 'Ouvrir l\'Atelier'
  },
  'workbench.mark_delivered': {
    'zh-Hans': '标记为已交付',
    'en': 'Mark as Delivered',
    'ja': '納品完了にする',
    'ko': '배송 완료로 표시',
    'fr': 'Marquer comme Livré'
  },

  // Purchase Order
  'purchase.title': {
    'zh-Hans': '采买建议单',
    'en': 'Purchase Order',
    'ja': '仕入れ提案書',
    'ko': '구매 발주서',
    'fr': 'Bon de Commande Fournisseur'
  },
  'purchase.supplier_note': {
    'zh-Hans': '花市采购推荐清单',
    'en': 'Flower Market Restock List',
    'ja': '花市場 仕入れ推奨リスト',
    'ko': '화훼시장 발주 추천 목록',
    'fr': 'Liste d\'Approvisionnement Marché'
  },
  'purchase.cost': {
    'zh-Hans': '进价',
    'en': 'Unit Cost',
    'ja': '仕入値',
    'ko': '매입가',
    'fr': 'Prix Achat'
  },
  'purchase.need': {
    'zh-Hans': '补货量',
    'en': 'Restock Qty',
    'ja': '補充数',
    'ko': '발주량',
    'fr': 'Qté à Commander'
  },
  'purchase.estimated_total': {
    'zh-Hans': '预估采买总额',
    'en': 'Estimated Total',
    'ja': '概算仕入総額',
    'ko': '예상 총 발주액',
    'fr': 'Total Estimé'
  },
  'purchase.no_low_stock': {
    'zh-Hans': '当前库存充盈，无需紧急采买',
    'en': 'Inventory is healthy. No urgent restocking required.',
    'ja': '在庫は十分です。緊急仕入れの必要はありません。',
    'ko': '현재 재고가 충분하여 긴급 발주가 필요하지 않습니다.',
    'fr': 'Stock suffisant. Aucun réapprovisionnement urgent requis.'
  },
  'purchase.notes': {
    'zh-Hans': '备注说明',
    'en': 'Notes',
    'ja': '備考',
    'ko': '비고',
    'fr': 'Notes'
  },

  // Poster Mode
  'poster.client.aesthetic': {
    'zh-Hans': '美学诠释',
    'en': 'Aesthetics',
    'ja': '美学的解釈',
    'ko': '미학적 해석',
    'fr': 'Interprétation Esthétique'
  },
  'poster.client.palette': {
    'zh-Hans': '配色方案',
    'en': 'Color Palette',
    'ja': '配色パレット',
    'ko': '컬러 팔레트',
    'fr': 'Palette de Couleurs'
  },
  'poster.client.retail_price': {
    'zh-Hans': '作品售价',
    'en': 'Price',
    'ja': '販売価格',
    'ko': '판매가',
    'fr': 'Prix de Vente'
  },
  'poster.mode.client': {
    'zh-Hans': '客户鉴赏海报',
    'en': 'Customer Poster',
    'ja': '顧客向けポスター',
    'ko': '고객용 포스터',
    'fr': 'Affiche Client'
  },
  'poster.mode.florist': {
    'zh-Hans': '花艺师制作单',
    'en': 'Florist Sheet',
    'ja': 'フローリスト制作シート',
    'ko': '플로리스트 제작표',
    'fr': 'Fiche Fleuriste'
  },

  // Design Result
  'result.title': {
    'zh-Hans': '花艺方案详情',
    'en': 'Design Proposal',
    'ja': 'デザインプラン詳細',
    'ko': '디자인 제안서 상세',
    'fr': 'Proposition de Design'
  },
  'result.bom.title': {
    'zh-Hans': '花材配比清单',
    'en': 'Bill of Materials',
    'ja': '花材構成表',
    'ko': '꽃재료 구성표',
    'fr': 'Composition Florale'
  },
  'result.cost.title': {
    'zh-Hans': '成本与定价核算',
    'en': 'Cost & Pricing',
    'ja': '原価・価格計算',
    'ko': '원가 및 판매가 산출',
    'fr': 'Coût et Tarification'
  },
  'result.imageError.title': {
    'zh-Hans': '效果图渲染异常',
    'en': 'Rendering Error',
    'ja': 'レンダリングエラー',
    'ko': '렌더링 오류',
    'fr': 'Erreur de Rendu'
  },
  'result.meaning.title': {
    'zh-Hans': '设计立意与花语',
    'en': 'Flower Meaning & Concept',
    'ja': '花言葉とデザインコンセプト',
    'ko': '꽃말 및 디자인 콘셉트',
    'fr': 'Langage des Fleurs et Concept'
  },
  'result.steps.title': {
    'zh-Hans': '插花制作指导',
    'en': 'Arrangement Instructions',
    'ja': '生け込み制作手順',
    'ko': '꽃꽂이 제작 단계',
    'fr': 'Instructions de Confection'
  },

  // Visual Muse & VM Options
  'design.vm.scale': {
    'zh-Hans': '尺寸规模',
    'en': 'Scale Preference',
    'ja': 'サイズ設定',
    'ko': '크기 설정',
    'fr': 'Échelle'
  },
  'design.vm.mood': {
    'zh-Hans': '情绪氛围',
    'en': 'Mood & Atmosphere',
    'ja': 'ムード・雰囲気',
    'ko': '무드/분위기',
    'fr': 'Ambiance'
  },
  'design.vm.form': {
    'zh-Hans': '形态构架',
    'en': 'Form & Structure',
    'ja': '形態・構造',
    'ko': '형태/구조',
    'fr': 'Forme & Structure'
  },
  'design.vm.bg': {
    'zh-Hans': '背景风格',
    'en': 'Background Style',
    'ja': '背景スタイル',
    'ko': '배경 스타일',
    'fr': 'Style d\'Arrière-plan'
  },
  'design.vm.options.title': {
    'zh-Hans': 'AI 视觉分析参数',
    'en': 'Visual Analysis Options',
    'ja': 'AI 視覚分析パラメータ',
    'ko': 'AI 시각 분석 매개변수',
    'fr': 'Options d\'Analyse Visuelle IA'
  },
  'design.vm.options.scale.auto': {
    'zh-Hans': '自动推断',
    'en': 'Auto Detect',
    'ja': '自動判定',
    'ko': '자동 감지',
    'fr': 'Automatique'
  },
  'design.vm.options.scale.micro': {
    'zh-Hans': '微型桌花',
    'en': 'Micro Petite',
    'ja': '極小・プチ',
    'ko': '초소형',
    'fr': 'Micro / Délicat'
  },
  'design.vm.options.scale.small': {
    'zh-Hans': '精致小品',
    'en': 'Small Compact',
    'ja': '小型・コンパクト',
    'ko': '소형',
    'fr': 'Petit / Compact'
  },
  'design.vm.options.scale.large': {
    'zh-Hans': '盛大作品',
    'en': 'Large Statement',
    'ja': '大型・華やか',
    'ko': '대형',
    'fr': 'Grand / Imposant'
  },
  'design.vm.options.mood.auto': {
    'zh-Hans': '智能感应',
    'en': 'Auto Mood',
    'ja': '自動認識',
    'ko': '자동 인식',
    'fr': 'Auto Détection'
  },
  'design.vm.options.mood.dramatic': {
    'zh-Hans': '浓墨戏剧',
    'en': 'Dramatic',
    'ja': 'ドラマチック',
    'ko': '드라마틱',
    'fr': 'Dramatique'
  },
  'design.vm.options.mood.romantic': {
    'zh-Hans': '柔情浪漫',
    'en': 'Romantic',
    'ja': 'ロマンチック',
    'ko': '로맨틱',
    'fr': 'Romantique'
  },
  'design.vm.options.mood.serene': {
    'zh-Hans': '素雅宁静',
    'en': 'Serene',
    'ja': '静寂・上品',
    'ko': '평온함',
    'fr': 'Serein & Épuré'
  },
  'design.vm.options.form.auto': {
    'zh-Hans': '自适应构型',
    'en': 'Auto Form',
    'ja': '自動形状',
    'ko': '자동 형태',
    'fr': 'Forme Auto'
  },
  'design.vm.options.form.cascade': {
    'zh-Hans': '瀑布悬垂',
    'en': 'Cascade Form',
    'ja': 'キャスケード',
    'ko': '캐스케이드',
    'fr': 'Cascade'
  },
  'design.vm.options.form.organic': {
    'zh-Hans': '自然野趣',
    'en': 'Organic Form',
    'ja': 'オーガニック',
    'ko': '유기적',
    'fr': 'Organique'
  },
  'design.vm.options.form.vertical': {
    'zh-Hans': '挺拔直立',
    'en': 'Vertical Form',
    'ja': 'バーティカル（直立）',
    'ko': '직립형',
    'fr': 'Vertical'
  },
  'design.vm.options.bg.auto': {
    'zh-Hans': '自动匹配',
    'en': 'Auto Background',
    'ja': '自動マッチング',
    'ko': '자동 배경',
    'fr': 'Arrière-plan Auto'
  },
  'design.vm.options.bg.luxe': {
    'zh-Hans': '奢雅静奢',
    'en': 'Luxurious',
    'ja': 'ラグジュアリー',
    'ko': '럭셔리',
    'fr': 'Luxueux'
  },
  'design.vm.options.bg.minimal': {
    'zh-Hans': '极简纯白',
    'en': 'Minimal White',
    'ja': 'ミニマル・白背景',
    'ko': '미니멀 화이트',
    'fr': 'Minimaliste Épuré'
  },

  // Design Steps and Execution
  'design.step.scene': {
    'zh-Hans': '选择场景',
    'en': 'Select Occasion',
    'ja': 'シーン選択',
    'ko': '상황 선택',
    'fr': 'Sélection de la Scène'
  },
  'design.step.target': {
    'zh-Hans': '对象与风格',
    'en': 'Recipient/Style',
    'ja': '対象とスタイル',
    'ko': '대상 및 스타일',
    'fr': 'Cible & Style'
  },
  'design.step.confirm': {
    'zh-Hans': '确认生成',
    'en': 'Confirm',
    'ja': '生成確認',
    'ko': '생성 확인',
    'fr': 'Confirmation'
  },
  'design.scene.muse': {
    'zh-Hans': '场景灵感',
    'en': 'Inspiration',
    'ja': 'シーンのインスピレーション',
    'ko': '상황 영감',
    'fr': 'Inspiration de Scène'
  },
  'design.scene.visual': {
    'zh-Hans': '以图生花 (Visual Muse)',
    'en': 'Visual Muse',
    'ja': '画像から花へ (Visual Muse)',
    'ko': '이미지로 꽃 만들기 (Visual Muse)',
    'fr': 'D\'Image à Fleur (Visual Muse)'
  },
  'design.action.generate': {
    'zh-Hans': '生成方案',
    'en': 'Generate Plan',
    'ja': 'プラン生成',
    'ko': '플랜 생성',
    'fr': 'Générer le Plan'
  },
  'design.action.render': {
    'zh-Hans': '生成效果图',
    'en': 'Render Visual',
    'ja': 'イメージ画像生成',
    'ko': '시각 렌더링',
    'fr': 'Générer le Visuel'
  },
  'design.execution.confirmTitle': {
    'zh-Hans': '确认执行方案',
    'en': 'Confirm Execution',
    'ja': 'プラン実行の確認',
    'ko': '플랜 실행 확인',
    'fr': 'Confirmer l\'Exécution'
  },
  'design.execution.confirmMessage': {
    'zh-Hans': '执行方案后将自动扣减店内对应花材库存。',
    'en': 'Executing will automatically deduct required flowers from inventory.',
    'ja': 'プランを実行すると、在庫から必要な花材が自動的に差し引かれます。',
    'ko': '플랜을 실행하면 필요한 꽃재료가 재고에서 자동 차감됩니다.',
    'fr': 'L\'exécution déduira automatiquement les fleurs requises du stock.'
  },
  'design.execution.executedAt': {
    'zh-Hans': '已于 %@ 执行出库',
    'en': 'Executed on %@',
    'ja': '%@ に出庫実行済み',
    'ko': '%@에 출고 완료됨',
    'fr': 'Exécuté le %@'
  },
  'design.execution.notExecuted': {
    'zh-Hans': '待出库执行',
    'en': 'Pending Execution',
    'ja': '出庫待ち',
    'ko': '출고 대기 중',
    'fr': 'En Attente d\'Exécution'
  },
  'design.execution.ratePrompt': {
    'zh-Hans': '为该方案的效果打分',
    'en': 'Rate this design',
    'ja': 'このデザインを評価',
    'ko': '이 디자인 평가하기',
    'fr': 'Évaluer cette création'
  },
  'design.execution.recordFeedback': {
    'zh-Hans': '记录制作心得或客户反馈...',
    'en': 'Record customer feedback or florist notes...',
    'ja': '制作の感想やお客様の反応を記録...',
    'ko': '제작 후기 또는 고객 피드백 기록...',
    'fr': 'Enregistrer les retours clients ou notes florales...'
  },
  'design.loading.analyzing': {
    'zh-Hans': '分析您的设计需求与偏好...',
    'en': 'Analyzing design requirements...',
    'ja': 'デザインの要件と好みを分析中...',
    'ko': '디자인 요구사항 및 선호도 분석 중...',
    'fr': 'Analyse des exigences et préférences...'
  },
  'design.loading.checkingStock': {
    'zh-Hans': '检索当前花材库存与成本...',
    'en': 'Checking inventory and costs...',
    'ja': '現在の在庫とコストを検索中...',
    'ko': '현재 재고 및 비용 검색 중...',
    'fr': 'Vérification du stock et des coûts...'
  },
  'design.loading.colorMatching': {
    'zh-Hans': '构建色彩搭配与空间结构...',
    'en': 'Constructing color harmony and space...',
    'ja': '配色と空間構造を構築中...',
    'ko': '색상 조화 및 공간 구조 구성 중...',
    'fr': 'Construction de la palette et de l\'harmonie...'
  },
  'design.loading.generating': {
    'zh-Hans': '生成最终效果图与花语...',
    'en': 'Generating final visual and flower meanings...',
    'ja': '最終イメージと花言葉を生成中...',
    'ko': '최종 이미지 및 꽃말 생성 중...',
    'fr': 'Génération du visuel final et des significations...'
  },
  'design.loading.parsingImage': {
    'zh-Hans': '视觉引擎正在解析参考图...',
    'en': 'Visual engine parsing image...',
    'ja': 'ビジュアルエンジンが参考画像を解析中...',
    'ko': '비주얼 엔진이 참고 이미지 분석 중...',
    'fr': 'Le moteur visuel analyse l\'image...'
  },

  // Home Screen Specifics
  'home.hero.studio_calm_title': {
    'zh-Hans': '花坊晨光',
    'en': 'Florist Studio',
    'ja': 'アトリエの朝',
    'ko': '꽃집의 아침',
    'fr': 'Atelier Floral'
  },
  'home.hero.studio_calm_subtitle': {
    'zh-Hans': '静享插花时光，从每一朵鲜花开始',
    'en': 'Crafting beauty, one blossom at a time',
    'ja': '一輪の花から広がる、静かな創作のひととき',
    'ko': '한 송이 꽃에서 시작되는 아름다운 창작의 시간',
    'fr': 'Créer la beauté, une fleur à la fois'
  },
  'home.hero.orders_pending': {
    'zh-Hans': '待处理',
    'en': 'Pending Orders',
    'ja': '対応待ち',
    'ko': '처리 대기',
    'fr': 'En Attente'
  },
  'home.hero.pending_count': {
    'zh-Hans': '%lld 笔待确认',
    'en': '%lld Pending',
    'ja': '%lld 件確認待ち',
    'ko': '%lld건 확인 대기',
    'fr': '%lld en attente'
  },
  'home.hero.in_production_count': {
    'zh-Hans': '%lld 束制作中',
    'en': '%lld In Production',
    'ja': '%lld 束制作中',
    'ko': '%lld다발 제작 중',
    'fr': '%lld en confection'
  },
  'home.hero.ready_count': {
    'zh-Hans': '%lld 件待自提/送达',
    'en': '%lld Ready for Pickup',
    'ja': '%lld 件受取/配達待ち',
    'ko': '%lld건 픽업/배송 대기',
    'fr': '%lld prêts à livrer'
  },
  'home.hero.view_orders': {
    'zh-Hans': '查看订单中心',
    'en': 'View Orders',
    'ja': '注文一覧を見る',
    'ko': '주문 관리 보기',
    'fr': 'Voir les Commandes'
  },
  'home.hero.stock_summary': {
    'zh-Hans': '在库 %lld 枝 · %lld 种告急',
    'en': '%lld stems in stock · %lld low',
    'ja': '在庫 %lld 本 · %lld 品目不足',
    'ko': '재고 %lld송이 · %lld종 부족',
    'fr': '%lld tiges en stock · %lld faibles'
  },
  'home.card.designer_role': {
    'zh-Hans': '首席花艺架构师',
    'en': 'Master Florist',
    'ja': 'チーフフローリスト',
    'ko': '수석 플로리스트',
    'fr': 'Maître Fleuriste'
  },
  'home.card.likes': {
    'zh-Hans': '点赞',
    'en': 'Likes',
    'ja': 'いいね',
    'ko': '좋아요',
    'fr': 'J\'aime'
  },
  'home.card.orders': {
    'zh-Hans': '订单',
    'en': 'Orders',
    'ja': '注文',
    'ko': '주문',
    'fr': 'Commandes'
  },
  'home.card.stars': {
    'zh-Hans': '星级',
    'en': 'Stars',
    'ja': '評価',
    'ko': '별점',
    'fr': 'Étoiles'
  },
  'home.inspiration.title': {
    'zh-Hans': '今日灵感',
    'en': 'Daily Inspiration',
    'ja': '今日のインスピレーション',
    'ko': '오늘의 영감',
    'fr': 'Inspiration du Jour'
  },
  'home.notifications.title': {
    'zh-Hans': '通知中心',
    'en': 'Notifications',
    'ja': 'お知らせ',
    'ko': '알림',
    'fr': 'Notifications'
  },
  'home.notifications.empty': {
    'zh-Hans': '暂无新通知',
    'en': 'No notifications',
    'ja': '新しい通知はありません',
    'ko': '새로운 알림이 없습니다',
    'fr': 'Aucune notification'
  },
  'home.notifications.emptyDesc': {
    'zh-Hans': '店内鲜花与订单运行平稳',
    'en': 'Studio inventory & orders are smooth',
    'ja': '店舗の在庫と注文は順調です',
    'ko': '매장 재고 및 주문이 원활합니다',
    'fr': 'Les stocks et commandes sont à jour'
  },
  'home.notifications.alert': {
    'zh-Hans': '预警',
    'en': 'Alert',
    'ja': 'アラート',
    'ko': '경고',
    'fr': 'Alerte'
  },
  'home.notifications.lowStock': {
    'zh-Hans': '%@ 库存告急',
    'en': '%@ is running low',
    'ja': '%@ の在庫が逼迫',
    'ko': '%@ 재고 부족',
    'fr': '%@ est en stock faible'
  },
  'home.notifications.only_left': {
    'zh-Hans': '仅剩 %lld 枝，请及时补货',
    'en': 'Only %lld left, restock soon',
    'ja': '残り %lld 本です。補充してください',
    'ko': '%lld송이 남았습니다. 발주를 서두르세요',
    'fr': 'Plus que %lld restantes, réapprovisionnez'
  },
  'home.notifications.replenish': {
    'zh-Hans': '生成采买建议',
    'en': 'Restock Suggestion',
    'ja': '仕入れ提案を作成',
    'ko': '발주 추천서 생성',
    'fr': 'Générer Bon d\'Achat'
  },
  'home.quickActions.title': {
    'zh-Hans': '快捷操作',
    'en': 'Quick Actions',
    'ja': 'クイックアクション',
    'ko': '빠른 작업',
    'fr': 'Actions Rapides'
  },
  'home.quickActions.addInventory': {
    'zh-Hans': '花材入库',
    'en': 'Add Inventory',
    'ja': '在庫追加',
    'ko': '재고 입고',
    'fr': 'Ajout Stock'
  },
  'home.quickActions.smartDesign': {
    'zh-Hans': '智能设计',
    'en': 'Smart Design',
    'ja': 'スマートデザイン',
    'ko': '스마트 디자인',
    'fr': 'Design Intelligent'
  },
  'home.quickActions.newOrder': {
    'zh-Hans': '快速录单',
    'en': 'New Order',
    'ja': 'クイック注文',
    'ko': '빠른 주문 등록',
    'fr': 'Nouvelle Commande'
  },
  'home.quickActions.design_title': {
    'zh-Hans': 'AI 方案定制',
    'en': 'AI Design Wizard',
    'ja': 'AI プラン作成',
    'ko': 'AI 디자인 마법사',
    'fr': 'Assistant IA Floral'
  },
  'home.quickActions.design_sub': {
    'zh-Hans': '三步生成花礼',
    'en': '3-Step Custom Floral',
    'ja': '3ステップで花礼作成',
    'ko': '3단계로 꽃 선물 생성',
    'fr': 'Création en 3 étapes'
  },
  'home.quickActions.restock_title': {
    'zh-Hans': '花材新进',
    'en': 'Stock Inflow',
    'ja': '新入荷',
    'ko': '꽃재료 입고',
    'fr': 'Arrivage Fleurs'
  },
  'home.quickActions.restock_sub': {
    'zh-Hans': '记录进货成本',
    'en': 'Record arrivals & cost',
    'ja': '原価・仕入れを記録',
    'ko': '입고 원가 기록',
    'fr': 'Saisir les arrivages'
  },
  'home.quickActions.order_title': {
    'zh-Hans': '客户订单',
    'en': 'Client Order',
    'ja': '顧客注文',
    'ko': '고객 주문',
    'fr': 'Commande Client'
  },
  'home.quickActions.order_sub': {
    'zh-Hans': '即时开单',
    'en': 'Direct Entry',
    'ja': '即時受付',
    'ko': '즉시 접수',
    'fr': 'Saisie Directe'
  },
  'home.quickActions.inspirationTitle': {
    'zh-Hans': '今日灵感',
    'en': 'Daily Inspiration',
    'ja': '今日のインスピレーション',
    'ko': '오늘의 영감',
    'fr': 'Inspiration du Jour'
  },
  'home.quickActions.inspirationText': {
    'zh-Hans': '“插花是无声的诗，立体的画。” 尝试在今天的作品中加入一点点尤加利叶，为作品增添几分自然的呼吸感。',
    'en': '"Flower arranging is silent poetry, three-dimensional painting." Try adding a bit of eucalyptus to today\'s work to add a natural breath.',
    'ja': '「生け花は無言の詩、立体の絵画。」 今日の作品に少しユーカリを加えて、自然な息吹を吹き込んでみてはいかがでしょうか。',
    'ko': '“꽃꽂이는 무언의 시이자 입체적인 그림입니다.” 오늘 작품에 유칼립투스를 조금 더해 자연스러운 호흡을 불어넣어 보는 건 어떨까요?',
    'fr': '« L\'art floral est une poésie silencieuse, une peinture vivante. » Ajoutez une touche d\'eucalyptus à votre création pour lui insuffler un souffle naturel.'
  },
  'home.section.actions': {
    'zh-Hans': '快捷工作台',
    'en': 'Workspace Actions',
    'ja': 'クイックワークスペース',
    'ko': '빠른 작업 공간',
    'fr': 'Actions Rapides'
  },
  'home.section.gallery_subtitle': {
    'zh-Hans': '沉浸式浏览花店精选作品集',
    'en': 'Curated arrangements portfolio',
    'ja': '厳選作品ポートフォリオ',
    'ko': '엄선된 플로럴 포트폴리오',
    'fr': 'Portfolio de Créations Florales'
  },
  'home.section.overview': {
    'zh-Hans': '今日经营概况',
    'en': 'Studio Overview',
    'ja': '本日の経営概況',
    'ko': '오늘의 매장 현황',
    'fr': 'Aperçu du Jour'
  },
  'home.section.recent_designs': {
    'zh-Hans': '最近设计档案',
    'en': 'Recent Design Archive',
    'ja': '最近のデザイン記録',
    'ko': '최근 디자인 기록',
    'fr': 'Archives Récentes'
  },

  // Inventory Rows & Shortage
  'inventory.stock': {
    'zh-Hans': '当前库存',
    'en': 'In Stock',
    'ja': '現在庫',
    'ko': '현재 재고',
    'fr': 'En Stock'
  },
  'inventory.row.margin': {
    'zh-Hans': '毛利率',
    'en': 'Margin',
    'ja': '粗利率',
    'ko': '마진율',
    'fr': 'Marge'
  },
  'inventory.row.quick_add': {
    'zh-Hans': '快速补货',
    'en': 'Quick Restock',
    'ja': 'クイック補充',
    'ko': '빠른 입고',
    'fr': 'Réappro Rapide'
  },
  'inventory.row.quick_waste': {
    'zh-Hans': '损耗折损',
    'en': 'Waste Loss',
    'ja': '廃棄ロス',
    'ko': '폐기 손실',
    'fr': 'Pertes & Déchets'
  },
  'inventory.row.stock': {
    'zh-Hans': '在库: %lld 枝',
    'en': 'Stock: %lld',
    'ja': '在庫: %lld 本',
    'ko': '재고: %lld송이',
    'fr': 'Stock : %lld tiges'
  },
  'inventory.row.used': {
    'zh-Hans': '累计消耗 %lld 枝',
    'en': 'Used: %lld',
    'ja': '累計消費: %lld 本',
    'ko': '누적 사용: %lld송이',
    'fr': 'Utilisé : %lld tiges'
  },
  'inventory.search.clear': {
    'zh-Hans': '清除筛选',
    'en': 'Clear Filter',
    'ja': 'フィルターを解除',
    'ko': '필터 지우기',
    'fr': 'Effacer le filtre'
  },
  'inventory.search.empty': {
    'zh-Hans': '未找到相关花材',
    'en': 'No flowers found',
    'ja': '該当する花材が見つかりません',
    'ko': '검색된 꽃재료가 없습니다',
    'fr': 'Aucune fleur trouvée'
  },
  'inventory.search.empty.desc': {
    'zh-Hans': '尝试更换花材名称或分类关键词',
    'en': 'Try searching with a different name or category',
    'ja': '別の名前やカテゴリーで検索してください',
    'ko': '다른 꽃 이름이나 카테고리로 검색해보세요',
    'fr': 'Essayez avec un autre nom ou catégorie'
  },
  'inventory.section.details': {
    'zh-Hans': '花材属性与价格',
    'en': 'Attributes & Pricing',
    'ja': '属性・価格情報',
    'ko': '속성 및 가격 정보',
    'fr': 'Attributs et Tarifs'
  },
  'inventory.section.stock': {
    'zh-Hans': '库存与出入库',
    'en': 'Stock & Movements',
    'ja': '在庫・入出庫管理',
    'ko': '재고 및 입출고 관리',
    'fr': 'Stock et Mouvements'
  },
  'inventory.shortage.title': {
    'zh-Hans': '花材库存不足提示',
    'en': 'Low Stock Alert',
    'ja': '花材在庫不足の警告',
    'ko': '꽃재료 재고 부족 안내',
    'fr': 'Alerte Stock Insuffisant'
  },
  'inventory.shortage.item': {
    'zh-Hans': '%@ 缺口 %lld 枝 (现有 %lld)',
    'en': '%@ short by %lld (in stock %lld)',
    'ja': '%@ %lld 本不足 (現在庫 %lld)',
    'ko': '%@ %lld송이 부족 (현재고 %lld)',
    'fr': '%@ manque de %lld (en stock %lld)'
  },
  'inventory.shortage.continue': {
    'zh-Hans': '仍要继续出库',
    'en': 'Proceed Anyway',
    'ja': 'このまま出庫を続ける',
    'ko': '계속 출고 진행',
    'fr': 'Poursuivre la Sortie'
  },

  // General & Errors
  'general.ok': {
    'zh-Hans': '确定',
    'en': 'OK',
    'ja': '確定',
    'ko': '확인',
    'fr': 'OK'
  },
  'general.cancel': {
    'zh-Hans': '取消',
    'en': 'Cancel',
    'ja': 'キャンセル',
    'ko': '취소',
    'fr': 'Annuler'
  },
  'general.done': {
    'zh-Hans': '完成',
    'en': 'Done',
    'ja': '完了',
    'ko': '완료',
    'fr': 'Terminé'
  },
  'general.delete': {
    'zh-Hans': '删除',
    'en': 'Delete',
    'ja': '削除',
    'ko': '삭제',
    'fr': 'Supprimer'
  },
  'general.error': {
    'zh-Hans': '错误',
    'en': 'Error',
    'ja': 'エラー',
    'ko': '오류',
    'fr': 'Erreur'
  },
  'general.save': {
    'zh-Hans': '保存',
    'en': 'Save',
    'ja': '保存',
    'ko': '저장',
    'fr': 'Enregistrer'
  },
  'general.search': {
    'zh-Hans': '搜索',
    'en': 'Search',
    'ja': '検索',
    'ko': '검색',
    'fr': 'Rechercher'
  },
  'common.done': {
    'zh-Hans': '完成',
    'en': 'Done',
    'ja': '完了',
    'ko': '완료',
    'fr': 'Terminé'
  },

  'error.api.insufficientQuota': {
    'zh-Hans': '点数余额不足，请前往设置或订阅中心充值。',
    'en': 'Insufficient credits. Please recharge in Settings.',
    'ja': 'クレジット残高が不足しています。設定からチャージしてください。',
    'ko': '크레딧이 부족합니다. 설정에서 충전해 주세요.',
    'fr': 'Crédits insuffisants. Veuillez recharger dans les Paramètres.'
  },
  'error.api.invalidResponse': {
    'zh-Hans': '服务响应异常，请稍后重试。',
    'en': 'Invalid service response, please retry later.',
    'ja': 'サービスの応答が無効です。後でもう一度お試しください。',
    'ko': '서비스 응답이 유효하지 않습니다. 잠시 후 다시 시도해 주세요.',
    'fr': 'Réponse de service invalide, veuillez réessayer.'
  },
  'error.apiError': {
    'zh-Hans': 'AI 服务处理失败',
    'en': 'AI service failed',
    'ja': 'AIサービスの処理に失敗しました',
    'ko': 'AI 서비스 처리 실패',
    'fr': 'Échec du service IA'
  },
  'error.authentication': {
    'zh-Hans': '登录凭证无效或已过期，请重新登录。',
    'en': 'Authentication expired, please sign in again.',
    'ja': 'ログイン認証の期限が切れました。再ログインしてください。',
    'ko': '인증이 만료되었습니다. 다시 로그인해 주세요.',
    'fr': 'Session expirée, veuillez vous reconnecter.'
  },
  'error.imageEncodingFailed': {
    'zh-Hans': '图片压缩或编码失败，请更换格式重试。',
    'en': 'Image encoding failed, please try another image.',
    'ja': '画像のエンコードに失敗しました。別の形式でお試しください。',
    'ko': '이미지 인코딩에 실패했습니다. 다른 이미지를 사용해 주세요.',
    'fr': 'Échec de l\'encodage de l\'image.'
  },
  'error.invalidImageData': {
    'zh-Hans': '无效的图像数据',
    'en': 'Invalid image data',
    'ja': '無効な画像データです',
    'ko': '유효하지 않은 이미지 데이터입니다',
    'fr': 'Données d\'image invalides'
  },
  'error.invalidURL': {
    'zh-Hans': '无效的服务请求地址',
    'en': 'Invalid service URL',
    'ja': '無効なURLです',
    'ko': '유효하지 않은 URL입니다',
    'fr': 'URL de service invalide'
  },
  'error.missingApiKey': {
    'zh-Hans': '未配置 API Key，请在系统设置中填入。',
    'en': 'Missing API Key, please configure in Settings.',
    'ja': 'APIキーが設定されていません。システム設定で入力してください。',
    'ko': 'API 키가 누락되었습니다. 설정에서 입력해 주세요.',
    'fr': 'Clé API manquante, veuillez la configurer.'
  },
  'error.network': {
    'zh-Hans': '网络连接失败，请检查网络设置。',
    'en': 'Network connection failed, check your connection.',
    'ja': 'ネットワーク接続に失敗しました。通信環境をご確認ください。',
    'ko': '네트워크 연결에 실패했습니다. 연결을 확인해 주세요.',
    'fr': 'Échec de connexion réseau.'
  },
  'error.saveImage': {
    'zh-Hans': '保存图片至相册失败',
    'en': 'Failed to save image to Photos',
    'ja': '写真への保存に失敗しました',
    'ko': '사진 앱에 이미지 저장 실패',
    'fr': 'Échec de l\'enregistrement dans Photos'
  },
  'error.serverUnavailable': {
    'zh-Hans': '服务暂时不可用，请稍后重试。',
    'en': 'Server temporarily unavailable, please retry later.',
    'ja': 'サーバーが利用できません。後でもう一度お試しください。',
    'ko': '서버를 일시적으로 사용할 수 없습니다.',
    'fr': 'Serveur temporairement indisponible.'
  },

  // Culture Filters
  'filter.culture.all': {
    'zh-Hans': '全部流派',
    'en': 'All Cultures',
    'ja': 'すべての文化',
    'ko': '전체 문화',
    'fr': 'Toutes Cultures'
  },
  'filter.culture.chinese': {
    'zh-Hans': '中式花艺',
    'en': 'Chinese Floristry',
    'ja': '中華風',
    'ko': '중국식',
    'fr': 'Art Floral Chinois'
  },
  'filter.culture.japanese': {
    'zh-Hans': '日式花道',
    'en': 'Japanese Ikebana',
    'ja': '日本いけばな',
    'ko': '일본 화도',
    'fr': 'Ikebana Japonais'
  },
  'filter.culture.western': {
    'zh-Hans': '欧式花艺',
    'en': 'Western Floral',
    'ja': '洋風アレンジ',
    'ko': '서양식',
    'fr': 'Art Floral Européen'
  },

  // Settings extra keys
  'settings.account': {
    'zh-Hans': '店铺与账号',
    'en': 'Shop & Account',
    'ja': '店舗・アカウント',
    'ko': '매장 및 계정',
    'fr': 'Boutique & Compte'
  },
  'settings.aiService': {
    'zh-Hans': 'AI 生成引擎',
    'en': 'AI Generation Engine',
    'ja': 'AI 生成エンジン',
    'ko': 'AI 생성 엔진',
    'fr': 'Moteur de Génération IA'
  },
  'settings.aiServiceManaged': {
    'zh-Hans': '官方全托管高速通道 (Cloudflare Edge)',
    'en': 'Managed Edge Service (Cloudflare Edge)',
    'ja': '公式フルマネージド高速チャンネル (Cloudflare Edge)',
    'ko': '공식 풀매니지드 고속 채널 (Cloudflare Edge)',
    'fr': 'Service Officiel Managé (Cloudflare Edge)'
  },
  'settings.aiServiceManagedDesc': {
    'zh-Hans': '免配置 API Key，开箱即用，已由系统统一调度加速。',
    'en': 'No API Key required. Plug and play, accelerated by global edge.',
    'ja': 'APIキーの設定は不要。箱から出してすぐに高速利用可能です。',
    'ko': 'API 키 설정 불필요. 글로벌 엣지로 가속화되어 즉시 사용 가능합니다.',
    'fr': 'Aucune clé requise. Prêt à l\'emploi, accéléré par le réseau Edge.'
  },
  'settings.aiServiceMode': {
    'zh-Hans': 'AI 服务接入模式',
    'en': 'AI Access Mode',
    'ja': 'AI 接続モード',
    'ko': 'AI 연결 모드',
    'fr': 'Mode d\'Accès IA'
  },
  'settings.apiKey': {
    'zh-Hans': '自定义 API Key',
    'en': 'Custom API Key',
    'ja': 'カスタム API キー',
    'ko': '사용자 지정 API 키',
    'fr': 'Clé API Personnalisée'
  },
  'settings.apiProvider': {
    'zh-Hans': 'API 提供商',
    'en': 'API Provider',
    'ja': 'API プロバイダー',
    'ko': 'API 제공자',
    'fr': 'Fournisseur API'
  },
  'settings.businessRules': {
    'zh-Hans': '花店业务参数',
    'en': 'Business Rules',
    'ja': '店舗業務ルール',
    'ko': '매장 비즈니스 규칙',
    'fr': 'Règles Commerciales'
  },
  'settings.defaultBudget': {
    'zh-Hans': '默认方案预算 (元)',
    'en': 'Default Budget (CNY)',
    'ja': 'デフォルト予算 (円)',
    'ko': '기본 예산 (원)',
    'fr': 'Budget par Défaut'
  },
  'settings.endpoint': {
    'zh-Hans': '接口 Base URL',
    'en': 'API Base URL',
    'ja': 'ベース URL',
    'ko': 'API 기본 URL',
    'fr': 'URL de Base'
  },
  'settings.fetching_quota': {
    'zh-Hans': '正在同步点数...',
    'en': 'Syncing credits...',
    'ja': 'クレジットを同期中...',
    'ko': '크레딧 동기화 중...',
    'fr': 'Synchronisation des crédits...'
  },
  'settings.imageEndpoint': {
    'zh-Hans': '生图 API 地址',
    'en': 'Image API URL',
    'ja': '作画 API アドレス',
    'ko': '이미지 API 주소',
    'fr': 'URL API Image'
  },
  'settings.imageModel': {
    'zh-Hans': '绘图模型',
    'en': 'Image Model',
    'ja': '作画モデル',
    'ko': '이미지 생성 모델',
    'fr': 'Modèle d\'Image'
  },
  'settings.language': {
    'zh-Hans': '应用界面语言',
    'en': 'App Language',
    'ja': '言語設定',
    'ko': '앱 언어',
    'fr': 'Langue de l\'Application'
  },
  'settings.logout': {
    'zh-Hans': '退出登录',
    'en': 'Sign Out',
    'ja': 'ログアウト',
    'ko': '로그아웃',
    'fr': 'Se Déconnecter'
  },
  'settings.logoutConfirmMessage': {
    'zh-Hans': '确定要退出当前工作区吗？本地离线缓存将被妥善保留。',
    'en': 'Are you sure you want to sign out? Offline cache is preserved.',
    'ja': 'ログアウトしますか？オフラインキャッシュは安全に保持されます。',
    'ko': '로그아웃하시겠습니까? 오프라인 캐시는 안전하게 유지됩니다.',
    'fr': 'Voulez-vous vous déconnecter ? Le cache hors ligne sera conservé.'
  },
  'settings.logoutConfirmTitle': {
    'zh-Hans': '退出登录确认',
    'en': 'Sign Out Confirmation',
    'ja': 'ログアウト確認',
    'ko': '로그아웃 확인',
    'fr': 'Confirmation de Déconnexion'
  },
  'settings.logoutHint': {
    'zh-Hans': '退出后需要重新输入凭据登录。',
    'en': 'Credentials required upon next sign-in.',
    'ja': 'ログアウト後は再度認証が必要になります。',
    'ko': '로그아웃 후 다시 로그인해야 합니다.',
    'fr': 'Vos identifiants seront requis à la prochaine connexion.'
  },
  'settings.lowStockWarning': {
    'zh-Hans': '低库存预警阈值 (枝)',
    'en': 'Low Stock Threshold (stems)',
    'ja': '低在庫アラート閾値 (本)',
    'ko': '재고 부족 경고 임계값 (송이)',
    'fr': 'Seuil d\'Alerte Stock Bas (tiges)'
  },
  'settings.modelName': {
    'zh-Hans': '文本模型名称',
    'en': 'Text Model Name',
    'ja': 'テキストモデル名',
    'ko': '텍스트 모델명',
    'fr': 'Nom du Modèle Texte'
  },
  'settings.provider': {
    'zh-Hans': '服务商',
    'en': 'Provider',
    'ja': 'プロバイダー',
    'ko': '제공자',
    'fr': 'Fournisseur'
  },
  'settings.quota': {
    'zh-Hans': '点数额度',
    'en': 'Quota',
    'ja': '利用可能枠',
    'ko': '한도',
    'fr': 'Quota'
  },
  'settings.quota_balance': {
    'zh-Hans': '剩余点数: %lld',
    'en': 'Remaining: %lld',
    'ja': '残り: %lld',
    'ko': '잔여: %lld',
    'fr': 'Restant : %lld'
  },
  'settings.saveConfig': {
    'zh-Hans': '保存所有配置',
    'en': 'Save Configuration',
    'ja': '設定を保存',
    'ko': '설정 저장',
    'fr': 'Enregistrer la Configuration'
  },
  'settings.saveSuccess': {
    'zh-Hans': '系统设置已更新',
    'en': 'Settings updated successfully',
    'ja': '設定を更新しました',
    'ko': '설정이 업데이트되었습니다',
    'fr': 'Paramètres mis à jour'
  },
  'settings.storeName': {
    'zh-Hans': '花店工作区名称',
    'en': 'Flower Shop Name',
    'ja': '店舗名',
    'ko': '꽃집 이름',
    'fr': 'Nom de la Boutique'
  },
  'settings.test.success': {
    'zh-Hans': '连接成功！API 正常响应。',
    'en': 'Connected successfully! API responded.',
    'ja': '接続成功！APIが正常に応答しました。',
    'ko': '연결 성공! API가 정상 응답했습니다.',
    'fr': 'Connexion réussie ! L\'API répond normalement.'
  },
  'settings.testConnection': {
    'zh-Hans': '测试连通性',
    'en': 'Test Connection',
    'ja': '接続テスト',
    'ko': '연결 테스트',
    'fr': 'Tester la Connexion'
  },
  'settings.textModel': {
    'zh-Hans': '文本推理模型',
    'en': 'Text Model',
    'ja': 'テキストモデル',
    'ko': '텍스트 모델',
    'fr': 'Modèle Texte'
  },
  'settings.visionModel': {
    'zh-Hans': '视觉多模态模型',
    'en': 'Vision Model',
    'ja': 'ビジョンモデル',
    'ko': '비전 모델',
    'fr': 'Modèle Vision'
  },
  'settings.api.model': {
    'zh-Hans': '模型',
    'en': 'Model',
    'ja': 'モデル',
    'ko': '모델',
    'fr': 'Modèle'
  },

  // Auth / Login
  'login.brand': {
    'zh-Hans': 'Floraboard 鲜花工坊',
    'en': 'Floraboard Studio',
    'ja': 'Floraboard アトリエ',
    'ko': 'Floraboard 플라워 아틀리에',
    'fr': 'Floraboard Studio Floral'
  },
  'login.createAccount': {
    'zh-Hans': '注册新花店',
    'en': 'Register Shop',
    'ja': '新規店舗登録',
    'ko': '새 매장 등록',
    'fr': 'Créer une Boutique'
  },
  'login.enter': {
    'zh-Hans': '进入数字工作区',
    'en': 'Enter Workspace',
    'ja': 'ワークスペースへ入る',
    'ko': '워크스페이스 입장',
    'fr': 'Entrer dans l\'Espace'
  },
  'login.hasAccount': {
    'zh-Hans': '已有账号？立即登录',
    'en': 'Have an account? Sign In',
    'ja': 'アカウントをお持ちの方はこちら',
    'ko': '계정이 있으신가요? 로그인',
    'fr': 'Déjà un compte ? Se connecter'
  },
  'login.noAccount': {
    'zh-Hans': '没有账号？立即注册',
    'en': 'No account? Sign Up',
    'ja': 'アカウントをお持ちでない方はこちら',
    'ko': '계정이 없으신가요? 가입하기',
    'fr': 'Pas encore de compte ? S\'inscrire'
  },
  'login.password': {
    'zh-Hans': '访问密码',
    'en': 'Password',
    'ja': 'パスワード',
    'ko': '비밀번호',
    'fr': 'Mot de Passe'
  },
  'login.storeName': {
    'zh-Hans': '花店名称',
    'en': 'Shop Name',
    'ja': '花屋の名前',
    'ko': '꽃집 이름',
    'fr': 'Nom de la Boutique'
  },

  // History Extra
  'history.empty.desc': {
    'zh-Hans': '您的创作之旅尚未开始。使用设计助手，只需几步即可生成精美的花艺方案。',
    'en': 'Your creative journey hasn\'t started yet. Use the Design Assistant to create beautiful arrangements in just a few steps.',
    'ja': 'まだデザインが作成されていません。デザインアシスタントを使って、素敵なプランを作りましょう。',
    'ko': '아직 디자인이 생성되지 않았습니다. 디자인 어시스턴트를 사용하여 멋진 플랜을 만들어보세요.',
    'fr': 'Votre voyage créatif n\'a pas encore commencé. Utilisez l\'assistant pour créer de beaux plans.'
  },
  'history.empty.action': {
    'zh-Hans': '去创建一个',
    'en': 'Create One',
    'ja': '作成しに行く',
    'ko': '만들러 가기',
    'fr': 'Créer maintenant'
  },
  'history.search.clear': {
    'zh-Hans': '清除搜索',
    'en': 'Clear Search',
    'ja': '検索をクリア',
    'ko': '검색 지우기',
    'fr': 'Effacer la Recherche'
  },
  'history.search.empty': {
    'zh-Hans': '未找到匹配的方案',
    'en': 'No designs matched',
    'ja': '一致するプランがありません',
    'ko': '일치하는 플랜이 없습니다',
    'fr': 'Aucun plan correspondant'
  },
  'history.search.empty.desc': {
    'zh-Hans': '尝试更换客户姓名或风格关键词',
    'en': 'Try searching by another customer or style',
    'ja': 'お客様名やスタイルを変更して再検索してください',
    'ko': '다른 고객명이나 스타일 키워드로 검색해보세요',
    'fr': 'Essayez avec un autre client ou style'
  },

  // Non-dotted keywords
  'Category': {
    'zh-Hans': '分类',
    'en': 'Category',
    'ja': 'カテゴリー',
    'ko': '카테고리',
    'fr': 'Catégorie'
  },
  'Count': {
    'zh-Hans': '数量',
    'en': 'Count',
    'ja': '数量',
    'ko': '수량',
    'fr': 'Quantité'
  },
  'Created with Floraboard': {
    'zh-Hans': '由 Floraboard 创作',
    'en': 'Created with Floraboard',
    'ja': 'Floraboard で作成',
    'ko': 'Floraboard로 제작됨',
    'fr': 'Créé avec Floraboard'
  },
  'Date': {
    'zh-Hans': '日期',
    'en': 'Date',
    'ja': '日付',
    'ko': '날짜',
    'fr': 'Date'
  },
  'Done': {
    'zh-Hans': '完成',
    'en': 'Done',
    'ja': '完了',
    'ko': '완료',
    'fr': 'Terminé'
  },
  'Floraboard': {
    'zh-Hans': 'Floraboard',
    'en': 'Floraboard',
    'ja': 'Floraboard',
    'ko': 'Floraboard',
    'fr': 'Floraboard'
  },
  'Floreboard': {
    'zh-Hans': 'Floreboard',
    'en': 'Floreboard',
    'ja': 'Floreboard',
    'ko': 'Floreboard',
    'fr': 'Floreboard'
  },
  'Petal & Bloom': {
    'zh-Hans': 'Petal & Bloom',
    'en': 'Petal & Bloom',
    'ja': 'Petal & Bloom',
    'ko': 'Petal & Bloom',
    'fr': 'Petal & Bloom'
  },
  'Revenue': {
    'zh-Hans': '营业额',
    'en': 'Revenue',
    'ja': '収益',
    'ko': '수익',
    'fr': 'Revenu'
  },
  'Status': {
    'zh-Hans': '状态',
    'en': 'Status',
    'ja': '状態',
    'ko': '상태',
    'fr': 'Statut'
  },
  '%@ (%@)': {
    'zh-Hans': '%1$@ (%2$@)',
    'en': '%1$@ (%2$@)',
    'ja': '%1$@ (%2$@)',
    'ko': '%1$@ (%2$@)',
    'fr': '%1$@ (%2$@)'
  },
  '%@ (%@: %lld)': {
    'zh-Hans': '%1$@ (%2$@: %3$lld)',
    'en': '%1$@ (%2$@: %3$lld)',
    'ja': '%1$@ (%2$@: %3$lld)',
    'ko': '%1$@ (%2$@: %3$lld)',
    'fr': '%1$@ (%2$@: %3$lld)'
  },
  '%@ %lld': {
    'zh-Hans': '%1$@ %2$lld',
    'en': '%1$@ %2$lld',
    'ja': '%1$@ %2$lld',
    'ko': '%1$@ %2$lld',
    'fr': '%1$@ %2$lld'
  },
  '%@, %@ %lld, %@': {
    'zh-Hans': '%1$@, %2$@ %3$lld, %4$@',
    'en': '%1$@, %2$@ %3$lld, %4$@',
    'ja': '%1$@, %2$@ %3$lld, %4$@',
    'ko': '%1$@, %2$@ %3$lld, %4$@',
    'fr': '%1$@, %2$@ %3$lld, %4$@'
  },
  '%@: %@': {
    'zh-Hans': '%1$@: %2$@',
    'en': '%1$@: %2$@',
    'ja': '%1$@: %2$@',
    'ko': '%1$@: %2$@',
    'fr': '%1$@: %2$@'
  },
  '%@: %lld': {
    'zh-Hans': '%1$@: %2$lld',
    'en': '%1$@: %2$lld',
    'ja': '%1$@: %2$lld',
    'ko': '%1$@: %2$lld',
    'fr': '%1$@: %2$lld'
  },
  'x%lld': {
    'zh-Hans': 'x%lld',
    'en': 'x%lld',
    'ja': 'x%lld',
    'ko': 'x%lld',
    'fr': 'x%lld'
  }
};

// Main function
function main() {
  console.log('--- Starting i18n Dictionary Synchronization ---');

  // Step 1: Read existing xcstrings
  if (!fs.existsSync(XSTRINGS_PATH)) {
    console.error(`Error: ${XSTRINGS_PATH} does not exist!`);
    process.exit(1);
  }
  const xcData = JSON.parse(fs.readFileSync(XSTRINGS_PATH, 'utf8'));
  const stringsMap = xcData.strings || {};
  console.log(`Loaded ${Object.keys(stringsMap).length} strings from Localizable.xcstrings`);

  // Step 2: Read Web's 5 locale files
  const webLocales = {};
  for (const [lang, filename] of Object.entries(LOCALE_FILE_MAP)) {
    const filePath = path.join(WEB_LOCALES_DIR, filename);
    if (!fs.existsSync(filePath)) {
      console.error(`Error: Web locale file ${filePath} not found!`);
      process.exit(1);
    }
    const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    webLocales[lang] = flattenObject(raw);
    console.log(`Loaded Web locale [${lang}] (${filename}): ${Object.keys(webLocales[lang]).length} keys`);
  }

  // Step 3: Collect all candidate keys
  const allKeys = new Set([
    ...Object.keys(stringsMap),
    ...Object.keys(webLocales['zh-Hans']),
    ...Object.keys(IOS_TRANSLATIONS)
  ]);
  console.log(`Total candidate unique keys: ${allKeys.size}`);

  let updatedCount = 0;
  let newKeyCount = 0;

  for (const key of allKeys) {
    if (!stringsMap[key]) {
      stringsMap[key] = {
        extractionState: 'manual',
        localizations: {}
      };
      newKeyCount++;
    }

    const entry = stringsMap[key];
    if (!entry.localizations) {
      entry.localizations = {};
    }

    // Determine values for each of the 5 languages
    for (const lang of ALL_LANGUAGES) {
      let val = null;

      // Priority 1: IOS_TRANSLATIONS explicit overrides
      if (IOS_TRANSLATIONS[key] && IOS_TRANSLATIONS[key][lang]) {
        val = IOS_TRANSLATIONS[key][lang];
      }

      // Priority 2: Web locale file
      if (!val && webLocales[lang] && webLocales[lang][key]) {
        val = webLocales[lang][key];
      }

      // Priority 3: WEB_FALLBACKS (for keys missing in ja/ko/fr in web)
      if (!val && WEB_FALLBACKS[key] && WEB_FALLBACKS[key][lang]) {
        val = WEB_FALLBACKS[key][lang];
      }

      // Priority 4: Existing entry in xcstrings
      if (!val && entry.localizations[lang] && entry.localizations[lang].stringUnit) {
        val = entry.localizations[lang].stringUnit.value;
      }

      // Priority 5: Fallback cascade for ja/ko/fr if still missing
      if (!val && (lang === 'ja' || lang === 'ko' || lang === 'fr')) {
        // Fallback to English, then zh-Hans
        const enVal = (IOS_TRANSLATIONS[key] && IOS_TRANSLATIONS[key]['en']) ||
          (webLocales['en'] && webLocales['en'][key]) ||
          (entry.localizations['en'] && entry.localizations['en'].stringUnit?.value);

        const zhVal = (IOS_TRANSLATIONS[key] && IOS_TRANSLATIONS[key]['zh-Hans']) ||
          (webLocales['zh-Hans'] && webLocales['zh-Hans'][key]) ||
          (entry.localizations['zh-Hans'] && entry.localizations['zh-Hans'].stringUnit?.value);

        val = enVal || zhVal;
      }

      // If we have a value and the entry doesn't have it or has a different value, update it
      if (val !== null && val !== undefined) {
        if (!entry.localizations[lang]) {
          entry.localizations[lang] = {
            stringUnit: {
              state: 'translated',
              value: val
            }
          };
          updatedCount++;
        } else {
          const currentVal = entry.localizations[lang].stringUnit?.value;
          if (currentVal !== val) {
            entry.localizations[lang].stringUnit = {
              state: 'translated',
              value: val
            };
            updatedCount++;
          }
        }
      }
    }

    // Sort the localizations keys alphabetically: "en", "fr", "ja", "ko", "zh-Hans"
    const sortedLocs = {};
    Object.keys(entry.localizations)
      .sort()
      .forEach(l => {
        sortedLocs[l] = entry.localizations[l];
      });
    entry.localizations = sortedLocs;
  }

  // Step 4: Sort all strings keys alphabetically
  const sortedStringsMap = {};
  Object.keys(stringsMap)
    .sort()
    .forEach(k => {
      sortedStringsMap[k] = stringsMap[k];
    });

  xcData.strings = sortedStringsMap;
  xcData.sourceLanguage = 'zh-Hans';
  xcData.version = '1.0';

  // Step 5: Write back to Localizable.xcstrings
  fs.writeFileSync(XSTRINGS_PATH, JSON.stringify(xcData, null, 2) + '\n', 'utf8');

  // Stats calculation
  const totalKeys = Object.keys(sortedStringsMap).length;
  const coverage = {};
  ALL_LANGUAGES.forEach(l => {
    let count = 0;
    for (const k of Object.keys(sortedStringsMap)) {
      if (sortedStringsMap[k].localizations && sortedStringsMap[k].localizations[l]?.stringUnit?.value) {
        count++;
      }
    }
    coverage[l] = count;
  });

  console.log(`\n--- Synchronization Complete ---`);
  console.log(`Total Keys in xcstrings: ${totalKeys} (added ${newKeyCount} new keys)`);
  console.log(`Localization Coverage:`);
  for (const [lang, count] of Object.entries(coverage)) {
    const pct = ((count / totalKeys) * 100).toFixed(1);
    console.log(`  - [${lang}]: ${count} / ${totalKeys} (${pct}%)`);
  }

  return { totalKeys, newKeyCount, coverage };
}

if (require.main === module) {
  main();
}

module.exports = { main };
