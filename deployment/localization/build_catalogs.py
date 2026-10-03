"""Generate Localizable.xcstrings and InfoPlist.xcstrings for Tagwise.

Keys are the English strings SwiftUI extracts. Edit translations here and rerun:
    python3 deployment/localization/build_catalogs.py
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "CoinConvert"
LANGS = ["es", "fr", "de", "it", "pt-BR", "ja", "ko", "zh-Hans"]

# key: (es, fr, de, it, pt-BR, ja, ko, zh-Hans)
T = {
    "%@, then %@.": ("%1$@, luego %2$@.", "%1$@, puis %2$@.", "%1$@, danach %2$@.", "%1$@, poi %2$@.", "%1$@, depois %2$@.", "%1$@、その後%2$@。", "%1$@, 이후 %2$@.", "%1$@，之后 %2$@。"),
    "%@. Change currency": ("%@. Cambiar moneda", "%@. Changer de devise", "%@. Währung ändern", "%@. Cambia valuta", "%@. Mudar moeda", "%@。通貨を変更", "%@. 통화 변경", "%@。更改货币"),
    "%lld%% off Lifetime": ("%lld %% de descuento en Vitalicio", "-%lld %% sur l'accès à vie", "%lld %% Rabatt auf Lebenslang", "%lld%% di sconto su A vita", "%lld%% de desconto no Vitalício", "買い切りが%lld%%オフ", "평생 이용권 %lld%% 할인", "终身版 %lld%% 折扣"),
    "A price tag reading %@, converted to %@.": ("Una etiqueta de precio de %1$@, convertida a %2$@.", "Une étiquette de prix de %1$@, convertie en %2$@.", "Ein Preisschild mit %1$@, umgerechnet %2$@.", "Un cartellino di %1$@, convertito in %2$@.", "Uma etiqueta de %1$@, convertida para %2$@.", "%1$@の値札、%2$@に換算。", "%1$@ 가격표, %2$@(으)로 환산.", "价签 %1$@，换算为 %2$@。"),
    "About": ("Información", "À propos", "Info", "Info", "Sobre", "情報", "정보", "关于"),
    "Active": ("Activa", "Active", "Aktiv", "Attivo", "Ativa", "有効", "활성", "已激活"),
    "All data stored locally": ("Todos los datos se guardan en el dispositivo", "Toutes les données restent sur l'appareil", "Alle Daten bleiben auf dem Gerät", "Tutti i dati restano sul dispositivo", "Todos os dados ficam no aparelho", "データはすべて端末内に保存", "모든 데이터는 기기에 저장", "所有数据都存储在本机"),
    "Allow camera": ("Permitir cámara", "Autoriser l'appareil photo", "Kamera erlauben", "Consenti fotocamera", "Permitir câmera", "カメラを許可", "카메라 허용", "允许使用相机"),
    "Allow the camera.": ("Permite la cámara.", "Autorisez l'appareil photo.", "Kamera erlauben.", "Consenti la fotocamera.", "Permita a câmera.", "カメラを許可。", "카메라를 허용하세요.", "允许使用相机。"),
    "Best Value": ("Mejor precio", "Meilleur prix", "Bestes Angebot", "Più conveniente", "Melhor valor", "最もお得", "최고 가성비", "最划算"),
    "Calculator": ("Calculadora", "Calculatrice", "Rechner", "Calcolatrice", "Calculadora", "計算機", "계산기", "计算器"),
    "Camera access is off": ("El acceso a la cámara está desactivado", "L'accès à l'appareil photo est désactivé", "Kamerazugriff ist aus", "L'accesso alla fotocamera è disattivato", "O acesso à câmera está desativado", "カメラへのアクセスがオフです", "카메라 접근이 꺼져 있습니다", "相机访问已关闭"),
    "Clear search": ("Borrar búsqueda", "Effacer la recherche", "Suche löschen", "Cancella ricerca", "Limpar busca", "検索をクリア", "검색 지우기", "清除搜索"),
    "Close": ("Cerrar", "Fermer", "Schließen", "Chiudi", "Fechar", "閉じる", "닫기", "关闭"),
    "Continue": ("Continuar", "Continuer", "Weiter", "Continua", "Continuar", "続ける", "계속", "继续"),
    "Couldn't complete the purchase. Try again.": ("No se pudo completar la compra. Inténtalo de nuevo.", "L'achat n'a pas abouti. Réessayez.", "Kauf fehlgeschlagen. Versuche es erneut.", "Acquisto non riuscito. Riprova.", "Não foi possível concluir a compra. Tente de novo.", "購入を完了できませんでした。もう一度お試しください。", "구매를 완료하지 못했습니다. 다시 시도하세요.", "无法完成购买，请重试。"),
    "Couldn't load plans. Check your connection.": ("No se pudieron cargar los planes. Revisa tu conexión.", "Impossible de charger les offres. Vérifiez votre connexion.", "Tarife konnten nicht geladen werden. Prüfe deine Verbindung.", "Impossibile caricare i piani. Controlla la connessione.", "Não foi possível carregar os planos. Verifique sua conexão.", "プランを読み込めませんでした。接続を確認してください。", "요금제를 불러오지 못했습니다. 연결을 확인하세요.", "无法加载方案，请检查网络连接。"),
    "Couldn't reach the exchange rate service.": ("No se pudo conectar con el servicio de tipos de cambio.", "Service de taux de change injoignable.", "Wechselkursdienst nicht erreichbar.", "Servizio dei tassi di cambio non raggiungibile.", "Não foi possível acessar o serviço de câmbio.", "為替レートサービスに接続できません。", "환율 서비스에 연결할 수 없습니다.", "无法连接汇率服务。"),
    "Couldn't read the latest rates. Try again later.": ("No se pudieron leer los tipos actuales. Inténtalo más tarde.", "Impossible de lire les derniers taux. Réessayez plus tard.", "Aktuelle Kurse konnten nicht gelesen werden. Versuche es später.", "Impossibile leggere i tassi aggiornati. Riprova più tardi.", "Não foi possível ler as cotações. Tente mais tarde.", "最新レートを読み込めませんでした。後でもう一度お試しください。", "최신 환율을 읽지 못했습니다. 나중에 다시 시도하세요.", "无法读取最新汇率，请稍后重试。"),
    "Currency": ("Moneda", "Devise", "Währung", "Valuta", "Moeda", "通貨", "통화", "货币"),
    "Detect local currency": ("Detectar moneda local", "Détecter la devise locale", "Landeswährung erkennen", "Rileva valuta locale", "Detectar moeda local", "現地通貨を検出", "현지 통화 감지", "检测当地货币"),
    "Exchange Rates": ("Tipos de cambio", "Taux de change", "Wechselkurse", "Tassi di cambio", "Câmbio", "為替レート", "환율", "汇率"),
    "Exchange rates are stored offline and can be updated when you have an internet connection.": ("Los tipos de cambio se guardan sin conexión y se actualizan cuando tienes internet.", "Les taux sont stockés hors ligne et se mettent à jour avec une connexion internet.", "Wechselkurse werden offline gespeichert und mit Internetverbindung aktualisiert.", "I tassi sono salvati offline e si aggiornano quando sei connesso.", "As cotações ficam salvas offline e são atualizadas quando há internet.", "為替レートはオフラインで保存され、インターネット接続時に更新されます。", "환율은 오프라인으로 저장되며 인터넷에 연결되면 업데이트됩니다.", "汇率离线保存，联网时更新。"),
    "Free for %@": ("Gratis durante %@", "Gratuit pendant %@", "%@ kostenlos", "Gratis per %@", "Grátis por %@", "%@無料", "%@ 무료", "免费 %@"),
    "Get started": ("Empezar", "Commencer", "Los geht's", "Inizia", "Começar", "はじめる", "시작하기", "开始"),
    "Home currency": ("Moneda local", "Devise de référence", "Heimatwährung", "Valuta di casa", "Moeda de casa", "ホーム通貨", "기본 통화", "本国货币"),
    "Home currency: %@. Tap to change.": ("Moneda local: %@. Toca para cambiar.", "Devise de référence : %@. Touchez pour changer.", "Heimatwährung: %@. Zum Ändern tippen.", "Valuta di casa: %@. Tocca per cambiare.", "Moeda de casa: %@. Toque para mudar.", "ホーム通貨：%@。タップして変更。", "기본 통화: %@. 탭하여 변경.", "本国货币：%@。轻点更改。"),
    "Last Updated": ("Última actualización", "Dernière mise à jour", "Zuletzt aktualisiert", "Ultimo aggiornamento", "Última atualização", "最終更新", "마지막 업데이트", "上次更新"),
    "Lifetime": ("Vitalicio", "À vie", "Lebenslang", "A vita", "Vitalício", "買い切り", "평생", "终身"),
    "Manage Subscription": ("Gestionar suscripción", "Gérer l'abonnement", "Abo verwalten", "Gestisci abbonamento", "Gerenciar assinatura", "サブスクリプションを管理", "구독 관리", "管理订阅"),
    "Most Popular": ("Más popular", "Le plus choisi", "Am beliebtesten", "Più scelto", "Mais popular", "一番人気", "가장 인기", "最受欢迎"),
    "No account required": ("Sin cuenta", "Aucun compte requis", "Kein Konto nötig", "Nessun account richiesto", "Sem conta", "アカウント不要", "계정 필요 없음", "无需账号"),
    "No ads or tracking": ("Sin anuncios ni rastreo", "Ni pub ni pistage", "Keine Werbung, kein Tracking", "Niente pubblicità né tracciamento", "Sem anúncios nem rastreamento", "広告・トラッキングなし", "광고 및 추적 없음", "无广告、无追踪"),
    "No connection. Rates will update when you're online.": ("Sin conexión. Los tipos se actualizarán cuando estés en línea.", "Pas de connexion. Les taux se mettront à jour en ligne.", "Keine Verbindung. Kurse werden online aktualisiert.", "Nessuna connessione. I tassi si aggiorneranno quando sarai online.", "Sem conexão. As cotações serão atualizadas quando estiver online.", "接続がありません。オンライン時にレートが更新されます。", "연결 없음. 온라인이 되면 환율이 업데이트됩니다.", "无网络连接。联网后将更新汇率。"),
    "No currency matches “%@”": ("Ninguna moneda coincide con «%@»", "Aucune devise ne correspond à « %@ »", "Keine Währung passt zu „%@“", "Nessuna valuta corrisponde a “%@”", "Nenhuma moeda corresponde a “%@”", "「%@」に一致する通貨はありません", "“%@”와(과) 일치하는 통화 없음", "没有与“%@”匹配的货币"),
    "No thanks": ("No, gracias", "Non merci", "Nein danke", "No, grazie", "Não, obrigado", "結構です", "괜찮습니다", "不用了"),
    "Not now": ("Ahora no", "Pas maintenant", "Nicht jetzt", "Non ora", "Agora não", "今はしない", "나중에", "以后再说"),
    "Not subscribed": ("Sin suscripción", "Non abonné", "Kein Abo", "Non abbonato", "Sem assinatura", "未登録", "구독 안 함", "未订阅"),
    "OK": ("OK", "OK", "OK", "OK", "OK", "OK", "확인", "好"),
    "One-time purchase of %@. No subscription.": ("Pago único de %@. Sin suscripción.", "Achat unique de %@. Sans abonnement.", "Einmalkauf für %@. Kein Abo.", "Acquisto unico di %@. Nessun abbonamento.", "Compra única de %@. Sem assinatura.", "%@の買い切り。サブスクリプションなし。", "%@ 일회성 구매. 구독 아님.", "一次性购买 %@，无需订阅。"),
    "One-time purchase. No subscription.": ("Pago único. Sin suscripción.", "Achat unique. Sans abonnement.", "Einmalkauf. Kein Abo.", "Acquisto unico. Nessun abbonamento.", "Compra única. Sem assinatura.", "買い切り。サブスクリプションなし。", "일회성 구매. 구독 아님.", "一次性购买，无需订阅。"),
    "Only used to read prices.": ("Solo para leer precios.", "Uniquement pour lire les prix.", "Nur zum Lesen von Preisen.", "Solo per leggere i prezzi.", "Só para ler preços.", "価格の読み取りにのみ使用します。", "가격을 읽는 데만 사용합니다.", "仅用于读取价格。"),
    "Open Settings": ("Abrir Ajustes", "Ouvrir Réglages", "Einstellungen öffnen", "Apri Impostazioni", "Abrir Ajustes", "設定を開く", "설정 열기", "打开设置"),
    "Point at any price.": ("Apunta a cualquier precio.", "Visez n'importe quel prix.", "Auf jeden Preis zeigen.", "Inquadra qualsiasi prezzo.", "Aponte para qualquer preço.", "値札にかざすだけ。", "가격에 비추기만 하세요.", "对准任意价格。"),
    "Privacy": ("Privacidad", "Confidentialité", "Datenschutz", "Privacy", "Privacidade", "プライバシー", "개인정보", "隐私"),
    "Privacy Policy": ("Política de privacidad", "Politique de confidentialité", "Datenschutzerklärung", "Informativa sulla privacy", "Política de privacidade", "プライバシーポリシー", "개인정보 처리방침", "隐私政策"),
    "Pro": ("Pro", "Pro", "Pro", "Pro", "Pro", "Pro", "Pro", "Pro"),
    "Purchase Error": ("Error de compra", "Erreur d'achat", "Kauffehler", "Errore di acquisto", "Erro na compra", "購入エラー", "구매 오류", "购买出错"),
    "Rates updated successfully": ("Tipos actualizados", "Taux mis à jour", "Kurse aktualisiert", "Tassi aggiornati", "Cotações atualizadas", "レートを更新しました", "환율을 업데이트했습니다", "汇率已更新"),
    "Auto-renews, cancel anytime.": ("Se renueva automáticamente; cancela cuando quieras.", "Renouvellement automatique, résiliable à tout moment.", "Verlängert sich automatisch, jederzeit kündbar.", "Rinnovo automatico, annulli quando vuoi.", "Renova automaticamente, cancele quando quiser.", "自動更新。いつでも解約できます。", "자동 갱신되며 언제든지 취소할 수 있습니다.", "自动续订，可随时取消。"),
    "Restore Purchases": ("Restaurar compras", "Restaurer les achats", "Käufe wiederherstellen", "Ripristina acquisti", "Restaurar compras", "購入を復元", "구매 복원", "恢复购买"),
    "Scan": ("Escanear", "Scanner", "Scannen", "Scansiona", "Escanear", "スキャン", "스캔", "扫描"),
    "Search": ("Buscar", "Rechercher", "Suchen", "Cerca", "Buscar", "検索", "검색", "搜索"),
    "See it in your money.": ("Velo en tu moneda.", "Voyez-le dans votre devise.", "In deiner Währung.", "Vedilo nella tua valuta.", "Veja na sua moeda.", "あなたの通貨で表示。", "내 통화로 바로 확인.", "以你的货币显示。"),
    "Settings": ("Ajustes", "Réglages", "Einstellungen", "Impostazioni", "Ajustes", "設定", "설정", "设置"),
    "Start Free Trial": ("Empezar prueba gratis", "Commencer l'essai gratuit", "Gratis testen", "Inizia la prova gratuita", "Começar teste grátis", "無料トライアルを開始", "무료 체험 시작", "开始免费试用"),
    "Step %lld of %lld": ("Paso %1$lld de %2$lld", "Étape %1$lld sur %2$lld", "Schritt %1$lld von %2$lld", "Passo %1$lld di %2$lld", "Etapa %1$lld de %2$lld", "ステップ %1$lld/%2$lld", "%2$lld단계 중 %1$lld단계", "第 %1$lld 步，共 %2$lld 步"),
    "Subscribe": ("Suscribirse", "S'abonner", "Abonnieren", "Abbonati", "Assinar", "登録する", "구독하기", "订阅"),
    "Subscribe to use Tagwise": ("Suscríbete para usar Tagwise", "Abonnez-vous pour utiliser Tagwise", "Abonniere, um Tagwise zu nutzen", "Abbonati per usare Tagwise", "Assine para usar o Tagwise", "Tagwiseを使うには登録が必要です", "Tagwise를 사용하려면 구독하세요", "订阅后即可使用 Tagwise"),
    "Subscription": ("Suscripción", "Abonnement", "Abo", "Abbonamento", "Assinatura", "サブスクリプション", "구독", "订阅"),
    "Supported Currencies": ("Monedas disponibles", "Devises prises en charge", "Unterstützte Währungen", "Valute supportate", "Moedas disponíveis", "対応通貨", "지원 통화", "支持的货币"),
    "Swap currencies": ("Intercambiar monedas", "Inverser les devises", "Währungen tauschen", "Inverti valute", "Inverter moedas", "通貨を入れ替え", "통화 바꾸기", "交换货币"),
    "Tagwise respects your privacy. Your currency preferences and exchange rates are stored only on your device.": ("Tagwise respeta tu privacidad. Tus monedas y tipos de cambio solo se guardan en tu dispositivo.", "Tagwise respecte votre vie privée. Vos devises et taux de change restent uniquement sur votre appareil.", "Tagwise respektiert deine Privatsphäre. Deine Währungen und Kurse werden nur auf deinem Gerät gespeichert.", "Tagwise rispetta la tua privacy. Valute e tassi di cambio restano solo sul tuo dispositivo.", "O Tagwise respeita sua privacidade. Suas moedas e cotações ficam só no seu aparelho.", "Tagwiseはプライバシーを尊重します。通貨設定と為替レートは端末内にのみ保存されます。", "Tagwise는 개인정보를 존중합니다. 통화 설정과 환율은 기기에만 저장됩니다.", "Tagwise 尊重你的隐私。你的货币偏好和汇率只保存在本机。"),
    "Terms of Use": ("Condiciones de uso", "Conditions d'utilisation", "Nutzungsbedingungen", "Termini di utilizzo", "Termos de uso", "利用規約", "이용약관", "使用条款"),
    "Try again": ("Reintentar", "Réessayer", "Erneut versuchen", "Riprova", "Tentar de novo", "再試行", "다시 시도", "重试"),
    "Turn on Camera for Tagwise in Settings to scan prices.": ("Activa la cámara para Tagwise en Ajustes para escanear precios.", "Activez l'appareil photo pour Tagwise dans Réglages pour scanner les prix.", "Aktiviere die Kamera für Tagwise in den Einstellungen, um Preise zu scannen.", "Attiva la fotocamera per Tagwise in Impostazioni per scansionare i prezzi.", "Ative a câmera do Tagwise em Ajustes para escanear preços.", "価格をスキャンするには、設定でTagwiseのカメラをオンにしてください。", "가격을 스캔하려면 설정에서 Tagwise의 카메라를 켜세요.", "请在“设置”中为 Tagwise 打开相机以扫描价格。"),
    "Turn on location in Settings": ("Activa la ubicación en Ajustes", "Activez la localisation dans Réglages", "Ortung in den Einstellungen aktivieren", "Attiva la posizione in Impostazioni", "Ative a localização em Ajustes", "設定で位置情報をオン", "설정에서 위치 켜기", "在“设置”中打开定位"),
    "Unlock Forever": ("Desbloquear para siempre", "Débloquer à vie", "Für immer freischalten", "Sblocca per sempre", "Desbloquear para sempre", "ずっと使えるようにする", "평생 잠금 해제", "永久解锁"),
    "Unlock Forever for %@": ("Desbloquear para siempre por %@", "Débloquer à vie pour %@", "Für %@ für immer freischalten", "Sblocca per sempre a %@", "Desbloquear para sempre por %@", "%@でずっと使える", "%@에 평생 잠금 해제", "%@ 永久解锁"),
    "Unlock Tagwise": ("Desbloquea Tagwise", "Débloquez Tagwise", "Tagwise freischalten", "Sblocca Tagwise", "Desbloqueie o Tagwise", "Tagwiseをアンロック", "Tagwise 잠금 해제", "解锁 Tagwise"),
    "Unlock camera scanning forever.\nPay once. No subscription.": ("Escaneo con cámara para siempre.\nUn solo pago. Sin suscripción.", "Le scan par caméra, à vie.\nUn seul paiement. Sans abonnement.", "Kamera-Scan für immer.\nEinmal zahlen. Kein Abo.", "Scansione con fotocamera per sempre.\nPaghi una volta. Nessun abbonamento.", "Escaneamento pela câmera para sempre.\nPague uma vez. Sem assinatura.", "カメラスキャンをずっと。\n一度の支払い。サブスクなし。", "카메라 스캔을 평생.\n한 번만 결제. 구독 없음.", "永久使用相机扫描。\n一次付费，无需订阅。"),
    "Update Rates Now": ("Actualizar tipos ahora", "Mettre à jour les taux", "Kurse jetzt aktualisieren", "Aggiorna i tassi ora", "Atualizar cotações", "レートを今すぐ更新", "지금 환율 업데이트", "立即更新汇率"),
    "Version": ("Versión", "Version", "Version", "Versione", "Versão", "バージョン", "버전", "版本"),
    "Wait — one-time offer": ("Espera: oferta única", "Attendez : offre unique", "Moment: einmaliges Angebot", "Aspetta: offerta unica", "Espere: oferta única", "お待ちください：今だけのオファー", "잠깐만요: 한정 혜택", "稍等：限时优惠"),
    "We convert to this.": ("Convertimos a esta.", "Nous convertissons dans celle-ci.", "Wir rechnen in diese um.", "Convertiamo in questa.", "Convertemos para ela.", "この通貨に換算します。", "이 통화로 환산합니다.", "我们会换算成这种货币。"),
    "Your home currency.": ("Tu moneda.", "Votre devise.", "Deine Heimatwährung.", "La tua valuta.", "Sua moeda.", "あなたのホーム通貨。", "기본 통화.", "你的本国货币。"),
    "day": ("día", "jour", "Tag", "giorno", "dia", "日", "일", "天"),
    "month": ("mes", "mois", "Monat", "mese", "mês", "月", "월", "月"),
    "one time": ("pago único", "paiement unique", "einmalig", "una tantum", "pagamento único", "買い切り", "일회성", "一次性"),
    "per %@": ("por %@", "par %@", "pro %@", "al %@", "por %@", "%@ごと", "%@당", "每%@"),
    "period": ("periodo", "période", "Zeitraum", "periodo", "período", "期間", "기간", "周期"),
    "Weekly": ("Semanal", "Hebdomadaire", "Wöchentlich", "Settimanale", "Semanal", "週間", "주간", "每周"),
    "Monthly": ("Mensual", "Mensuel", "Monatlich", "Mensile", "Mensal", "月間", "월간", "每月"),
    "week": ("semana", "semaine", "Woche", "settimana", "semana", "週", "주", "周"),
    "year": ("año", "an", "Jahr", "anno", "ano", "年", "년", "年"),
}

INFOPLIST = {
    "CFBundleDisplayName": ("Tagwise",) * 8,
    "NSCameraUsageDescription": (
        "Tagwise usa la cámara para leer precios y convertirlos.",
        "Tagwise utilise l'appareil photo pour lire les prix et les convertir.",
        "Tagwise nutzt die Kamera, um Preise zu lesen und umzurechnen.",
        "Tagwise usa la fotocamera per leggere i prezzi e convertirli.",
        "O Tagwise usa a câmera para ler preços e convertê-los.",
        "Tagwiseは値札を読み取って換算するためにカメラを使います。",
        "Tagwise는 가격을 읽고 환산하기 위해 카메라를 사용합니다.",
        "Tagwise 使用相机读取并换算价格。",
    ),
    "NSLocationWhenInUseUsageDescription": (
        "Tagwise usa tu ubicación para elegir la moneda local cuando viajas.",
        "Tagwise utilise votre position pour choisir la devise locale en voyage.",
        "Tagwise nutzt deinen Standort, um auf Reisen die Landeswährung zu wählen.",
        "Tagwise usa la tua posizione per scegliere la valuta locale quando viaggi.",
        "O Tagwise usa sua localização para escolher a moeda local quando você viaja.",
        "Tagwiseは旅行先の現地通貨を選ぶために位置情報を使います。",
        "Tagwise는 여행 중 현지 통화를 선택하기 위해 위치를 사용합니다.",
        "Tagwise 使用你的位置在旅行时选择当地货币。",
    ),
}


def catalog(table, extra_keys=()):
    strings = {}
    for key in extra_keys:
        strings[key] = {"shouldTranslate": False}
    for key, values in table.items():
        assert len(values) == len(LANGS), key
        strings[key] = {"localizations": {
            lang: {"stringUnit": {"state": "translated", "value": value}} for lang, value in zip(LANGS, values)
        }}
    return {"sourceLanguage": "en", "strings": dict(sorted(strings.items())), "version": "1.0"}


untranslated = ["%@ %@", "%@%@", "%lld", "•", "≈ %@"]

import sys
sys.path.insert(0, str(Path(__file__).parent))
from more_languages import MORE, MORE_INFOPLIST  # nl, ru, tr, th, id, pt-PT


def merge(cat, extra):
    """Add languages kept as {lang: {key: value}} (more_languages.py)."""
    for lang, values in extra.items():
        for key, value in values.items():
            cat["strings"][key].setdefault("localizations", {})[lang] = {
                "stringUnit": {"state": "translated", "value": value}}
    return cat


(ROOT / "Localizable.xcstrings").write_text(json.dumps(merge(catalog(T, untranslated), MORE), ensure_ascii=False, indent=2))
(ROOT / "InfoPlist.xcstrings").write_text(json.dumps(merge(catalog(INFOPLIST), MORE_INFOPLIST), ensure_ascii=False, indent=2))
print(f"Localizable: {len(T)} strings x {len(LANGS)} languages; InfoPlist: {len(INFOPLIST)} keys")

# Traditional Chinese is derived from Simplified with ICU's Hans-Hant transform.
import subprocess
subprocess.run(["swift", str(Path(__file__).with_name("add_hant.swift")),
                str(ROOT / "Localizable.xcstrings"), str(ROOT / "InfoPlist.xcstrings")], check=True)
