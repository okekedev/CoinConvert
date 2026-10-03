# -*- coding: utf-8 -*-
"""Tagwise — localized App Store listing, uploaded by ../asc_localize_metadata.py.

Fields per locale (App Store limits): name (<=30), subtitle (<=30), keywords (<=100,
no words already in name/subtitle), promotionalText (<=170), description, whatsNew.

en-US comes from the .txt files in this folder (pushed by asc_push_metadata.py).
en-GB/AU/CA reuse the English text with different keywords for extra search coverage.
Translations are model-written: spot-check es, fr, de, ja before submitting.
"""
from pathlib import Path

HERE = Path(__file__).parent
SUPPORT_URL = "https://okekedev.github.io/CoinConvert/support.html"
NAME = "Tagwise"


def _read(name):
    return (HERE / name).read_text().strip()


def _e(name, subtitle, keywords, promo, description, whats_new):
    return {"name": name, "subtitle": subtitle, "keywords": keywords, "promotionalText": promo,
            "description": description, "whatsNew": whats_new, "supportUrl": SUPPORT_URL}


_EN = dict(name=_read("app-store-title.txt"), subtitle=_read("subtitle.txt"),
           promo=_read("promotional-text.txt"), description=_read("description.txt"), whats_new=_read("whats-new.txt"))

LOCALIZATIONS = {
    "en-GB": _e(_EN["name"], _EN["subtitle"],
                "exchange,rate,money,holiday,abroad,euro,pound,sterling,fx,tip,menu,cash,travel,calculator,foreign",
                _EN["promo"], _EN["description"], _EN["whats_new"]),
    "en-AU": _e(_EN["name"], _EN["subtitle"],
                "exchange,rate,money,holiday,overseas,aud,dollar,fx,tip,menu,cash,travel,calculator,foreign,trip",
                _EN["promo"], _EN["description"], _EN["whats_new"]),
    "en-CA": _e(_EN["name"], _EN["subtitle"],
                "exchange,rate,money,cad,loonie,usd,fx,tip,menu,cash,travel,calculator,foreign,trip,shopping",
                _EN["promo"], _EN["description"], _EN["whats_new"]),

    "es-ES": _e("Tagwise: escanea precios", "Conversor de divisas", "cambio,moneda,euro,dólar,libra,viaje,calculadora,cámara,menú,tienda,extranjero,tipo",
        "¿Viajas? Apunta la cámara a cualquier etiqueta o menú y mira el precio en tu moneda al instante. Sin conexión, sin cuenta, sin anuncios.",
        """Apunta la cámara a cualquier precio y míralo al instante en tu moneda. Tagwise lee etiquetas, menús y tickets por ti, sin escribir nada.

CÓMO FUNCIONA
1. Apunta la cámara a un precio
2. El importe convertido aparece al momento
3. Pasa a la calculadora para dividir la cuenta o añadir propina

MONEDA LOCAL AUTOMÁTICA
Elige tu moneda una vez. Cuando viajas, Tagwise detecta el país y pone la moneda local por ti.

MÁS DE 150 MONEDAS · FUNCIONA SIN CONEXIÓN
Los tipos de cambio se guardan en el teléfono, así que sigue funcionando en el avión o sin datos.

PRIVADO
El escaneo ocurre en tu dispositivo. No se guardan ni se suben fotos. Sin cuenta, sin anuncios, sin rastreo.

TAGWISE PRO
Prueba gratis 3 días con el plan semanal o mensual, o compra Vitalicio con un solo pago. Las suscripciones se renuevan automáticamente salvo que se cancelen al menos 24 horas antes del final del periodo; gestiónalas en los ajustes de tu cuenta.

Condiciones: https://okekedev.github.io/CoinConvert/terms.html
Privacidad: https://okekedev.github.io/CoinConvert/privacy.html""",
        "Real Time Currency Conversion ahora es Tagwise: nuevo diseño, moneda local automática, calculadora y escáner en una sola pantalla, y tipos de cambio que se actualizan bien."),
}
LOCALIZATIONS["es-MX"] = dict(LOCALIZATIONS["es-ES"], keywords="cambio,moneda,peso,dólar,euro,viaje,calculadora,cámara,menú,tienda,extranjero,tipo,divisa")

LOCALIZATIONS["fr-FR"] = _e("Tagwise : scannez les prix", "Convertisseur de devises",
    "change,devise,euro,dollar,livre,voyage,calculatrice,caméra,menu,boutique,étranger,taux,monnaie",
    "En voyage ? Visez une étiquette ou un menu et voyez le prix dans votre devise. Hors ligne, sans compte, sans pub.",
    """Visez n'importe quel prix avec l'appareil photo et voyez-le aussitôt dans votre devise. Tagwise lit les étiquettes, menus et tickets pour vous, sans rien taper.

COMMENT ÇA MARCHE
1. Visez un prix
2. Le montant converti s'affiche aussitôt
3. Passez à la calculatrice pour partager l'addition ou ajouter un pourboire

DEVISE LOCALE AUTOMATIQUE
Choisissez votre devise une fois. En voyage, Tagwise détecte le pays et met la devise locale pour vous.

PLUS DE 150 DEVISES · FONCTIONNE HORS LIGNE
Les taux sont enregistrés sur le téléphone : ça marche aussi en avion ou sans données.

PRIVÉ
Le scan se fait sur l'appareil. Aucune photo n'est enregistrée ni envoyée. Sans compte, sans pub, sans pistage.

TAGWISE PRO
Essai gratuit de 3 jours avec la formule hebdomadaire ou mensuelle, ou achat unique « À vie ». Les abonnements se renouvellent automatiquement sauf résiliation au moins 24 heures avant la fin de la période ; gérez-les dans les réglages de votre compte.

Conditions : https://okekedev.github.io/CoinConvert/terms.html
Confidentialité : https://okekedev.github.io/CoinConvert/privacy.html""",
    "Real Time Currency Conversion devient Tagwise : nouveau design, devise locale automatique, calculatrice et scanner sur un seul écran, et des taux qui se mettent bien à jour.")
LOCALIZATIONS["fr-CA"] = dict(LOCALIZATIONS["fr-FR"], keywords="change,devise,dollar,huard,euro,voyage,calculatrice,caméra,menu,boutique,étranger,taux,monnaie")

LOCALIZATIONS["de-DE"] = _e("Tagwise: Preise scannen", "Währungsrechner mit Kamera",
    "umrechner,wechselkurs,euro,dollar,pfund,reise,urlaub,rechner,menü,ausland,geld,kurs,devisen",
    "Auf Reisen? Kamera auf ein Preisschild oder eine Speisekarte halten und den Preis in deiner Währung sehen. Offline, ohne Konto, ohne Werbung.",
    """Halte die Kamera auf einen Preis und sieh ihn sofort in deiner Währung. Tagwise liest Preisschilder, Speisekarten und Belege für dich – ohne Tippen.

SO FUNKTIONIERT'S
1. Kamera auf einen Preis halten
2. Der umgerechnete Betrag erscheint sofort
3. Zum Rechner wechseln, um die Rechnung zu teilen oder Trinkgeld zu addieren

LANDESWÄHRUNG AUTOMATISCH
Wähle einmal deine Heimatwährung. Auf Reisen erkennt Tagwise das Land und stellt die Landeswährung für dich ein.

ÜBER 150 WÄHRUNGEN · FUNKTIONIERT OFFLINE
Wechselkurse werden auf dem Handy gespeichert – auch im Flugzeug oder ohne Datenverbindung.

PRIVAT
Gescannt wird auf dem Gerät. Keine Fotos werden gespeichert oder hochgeladen. Kein Konto, keine Werbung, kein Tracking.

TAGWISE PRO
3 Tage gratis testen mit dem Wochen- oder Monatsabo, oder einmal „Lebenslang“ kaufen. Abos verlängern sich automatisch, wenn sie nicht mindestens 24 Stunden vor Ablauf gekündigt werden; verwalten in den Accounteinstellungen.

Nutzungsbedingungen: https://okekedev.github.io/CoinConvert/terms.html
Datenschutz: https://okekedev.github.io/CoinConvert/privacy.html""",
    "Aus Real Time Currency Conversion wird Tagwise: neues Design, automatische Landeswährung, Rechner und Scanner auf einem Bildschirm und zuverlässig aktualisierte Kurse.")

LOCALIZATIONS["it"] = _e("Tagwise: scansiona i prezzi", "Convertitore di valuta",
    "cambio,valuta,euro,dollaro,sterlina,viaggio,calcolatrice,fotocamera,menù,estero,tasso,soldi",
    "In viaggio? Inquadra un cartellino o un menù e vedi il prezzo nella tua valuta. Offline, senza account, senza pubblicità.",
    """Inquadra qualsiasi prezzo e vedilo subito nella tua valuta. Tagwise legge cartellini, menù e scontrini per te, senza digitare.

COME FUNZIONA
1. Inquadra un prezzo
2. L'importo convertito appare subito
3. Passa alla calcolatrice per dividere il conto o aggiungere la mancia

VALUTA LOCALE AUTOMATICA
Scegli una volta la tua valuta. In viaggio Tagwise riconosce il paese e imposta la valuta locale per te.

OLTRE 150 VALUTE · FUNZIONA OFFLINE
I tassi sono salvati sul telefono: funziona anche in aereo o senza dati.

PRIVATO
La scansione avviene sul dispositivo. Nessuna foto viene salvata o caricata. Niente account, pubblicità o tracciamento.

TAGWISE PRO
Prova gratis per 3 giorni con il piano settimanale o mensile, oppure acquista A vita con un solo pagamento. Gli abbonamenti si rinnovano automaticamente se non annullati almeno 24 ore prima della fine del periodo; gestiscili nelle impostazioni dell'account.

Termini: https://okekedev.github.io/CoinConvert/terms.html
Privacy: https://okekedev.github.io/CoinConvert/privacy.html""",
    "Real Time Currency Conversion ora si chiama Tagwise: nuovo design, valuta locale automatica, calcolatrice e scanner in un'unica schermata e tassi sempre aggiornati.")

LOCALIZATIONS["pt-BR"] = _e("Tagwise: escaneie preços", "Conversor de moedas",
    "câmbio,moeda,real,dólar,euro,viagem,calculadora,câmera,cardápio,exterior,cotação,dinheiro",
    "Viajando? Aponte a câmera para uma etiqueta ou cardápio e veja o preço na sua moeda na hora. Offline, sem conta, sem anúncios.",
    """Aponte a câmera para qualquer preço e veja na hora na sua moeda. O Tagwise lê etiquetas, cardápios e notas para você, sem digitar.

COMO FUNCIONA
1. Aponte a câmera para um preço
2. O valor convertido aparece na hora
3. Vá para a calculadora para dividir a conta ou somar a gorjeta

MOEDA LOCAL AUTOMÁTICA
Escolha sua moeda uma vez. Quando você viaja, o Tagwise detecta o país e escolhe a moeda local.

MAIS DE 150 MOEDAS · FUNCIONA OFFLINE
As cotações ficam salvas no celular: funciona no avião ou sem dados.

PRIVADO
O escaneamento acontece no aparelho. Nenhuma foto é salva ou enviada. Sem conta, sem anúncios, sem rastreamento.

TAGWISE PRO
Teste grátis por 3 dias no plano semanal ou mensal, ou compre o Vitalício com um único pagamento. As assinaturas renovam automaticamente, a menos que sejam canceladas pelo menos 24 horas antes do fim do período; gerencie nos ajustes da conta.

Termos: https://okekedev.github.io/CoinConvert/terms.html
Privacidade: https://okekedev.github.io/CoinConvert/privacy.html""",
    "O Real Time Currency Conversion agora é Tagwise: novo visual, moeda local automática, calculadora e scanner em uma só tela e cotações atualizadas corretamente.")

LOCALIZATIONS["ja"] = _e("Tagwise：値札をスキャン", "カメラで通貨換算",
    "為替,レート,円,ドル,ユーロ,旅行,海外,電卓,メニュー,外貨,両替,計算,買い物,免税",
    "旅行中？値札やメニューにカメラをかざすだけで、あなたの通貨の金額がすぐわかります。オフライン対応・アカウント不要・広告なし。",
    """カメラを値札にかざすだけで、あなたの通貨の金額がすぐにわかります。Tagwiseが値札・メニュー・レシートを読み取るので、入力は不要です。

使い方
1. 値札にカメラをかざす
2. 換算した金額がすぐに表示
3. 電卓に切り替えて割り勘やチップの計算も

現地通貨を自動で設定
ホーム通貨を一度選ぶだけ。旅行先では国を検出して、現地通貨を自動で設定します。

150以上の通貨・オフライン対応
為替レートは端末に保存されるので、機内やデータ通信なしでも使えます。

プライバシー
スキャンは端末内で行われます。写真は保存もアップロードもされません。アカウント・広告・トラッキングなし。

TAGWISE PRO
週間または月間プランは3日間無料でお試しいただけます。買い切りプランもあります。サブスクリプションは期間終了の24時間以上前に解約しない限り自動更新されます。アカウント設定で管理できます。

利用規約：https://okekedev.github.io/CoinConvert/terms.html
プライバシーポリシー：https://okekedev.github.io/CoinConvert/privacy.html""",
    "Real Time Currency Conversion は Tagwise になりました。新デザイン、現地通貨の自動設定、電卓とスキャナーを1画面に統合、為替レートの更新も改善しました。")

LOCALIZATIONS["ko"] = _e("Tagwise: 가격 스캔", "카메라 환율 계산기",
    "환율,환전,원,달러,유로,엔,여행,해외,계산기,메뉴,쇼핑,외화,면세",
    "여행 중이신가요? 가격표나 메뉴에 카메라를 비추면 내 통화로 바로 보여 드려요. 오프라인, 계정 없음, 광고 없음.",
    """카메라로 가격을 비추면 내 통화로 바로 보여 드립니다. Tagwise가 가격표, 메뉴, 영수증을 읽어 주니 입력할 필요가 없어요.

사용 방법
1. 가격에 카메라를 비추세요
2. 환산 금액이 바로 표시됩니다
3. 계산기로 전환해 더치페이나 팁을 계산하세요

현지 통화 자동 설정
기본 통화를 한 번만 고르세요. 여행 중에는 국가를 감지해 현지 통화를 자동으로 설정합니다.

150개 이상의 통화 · 오프라인 지원
환율이 휴대폰에 저장되어 기내나 데이터가 없을 때도 작동합니다.

개인정보 보호
스캔은 기기에서 처리됩니다. 사진은 저장되거나 업로드되지 않습니다. 계정, 광고, 추적 없음.

TAGWISE PRO
주간 또는 월간 요금제는 3일 무료 체험이 가능하며, 평생 이용권은 한 번만 결제합니다. 구독은 기간 종료 최소 24시간 전에 취소하지 않으면 자동 갱신되며, 계정 설정에서 관리할 수 있습니다.

이용약관: https://okekedev.github.io/CoinConvert/terms.html
개인정보 처리방침: https://okekedev.github.io/CoinConvert/privacy.html""",
    "Real Time Currency Conversion이 Tagwise로 바뀌었습니다. 새 디자인, 현지 통화 자동 설정, 계산기와 스캐너를 한 화면에, 환율 업데이트도 개선했습니다.")

LOCALIZATIONS["zh-Hans"] = _e("Tagwise：扫描价格", "相机货币换算器",
    "汇率,换算,人民币,美元,欧元,日元,旅行,出国,计算器,菜单,购物,外币,免税",
    "在旅行？把相机对准价签或菜单，立刻看到换算成你货币的价格。离线可用，无需账号，无广告。",
    """把相机对准任意价格，立刻看到换算成你货币的金额。Tagwise 帮你读取价签、菜单和小票，无需输入。

使用方法
1. 把相机对准价格
2. 立即显示换算后的金额
3. 切换到计算器，平摊账单或加小费

自动设置当地货币
只需选择一次本国货币。旅行时，Tagwise 会识别所在国家并自动设置当地货币。

150 多种货币 · 离线可用
汇率保存在手机上，在飞机上或没有网络时也能用。

隐私
扫描在设备上完成，不保存也不上传任何照片。无需账号，无广告，无追踪。

TAGWISE PRO
每周或每月方案可免费试用 3 天，也可一次性购买终身版。订阅会自动续订，除非在当期结束前至少 24 小时取消；可在账户设置中管理。

使用条款：https://okekedev.github.io/CoinConvert/terms.html
隐私政策：https://okekedev.github.io/CoinConvert/privacy.html""",
    "Real Time Currency Conversion 现已更名为 Tagwise：全新设计，自动设置当地货币，计算器和扫描器合为一屏，汇率更新更可靠。")

# ---- Additional markets (listing only; the app UI falls back to English except zh-Hant) ----

def _desc(how, s1, s2, s3, s4, s5, s6, pro_title, pro, terms, privacy):
    return f"""{how}

{s1}
{s2}

{s3}
{s4}

{s5}
{s6}

{pro_title}
{pro}

{terms}: https://okekedev.github.io/CoinConvert/terms.html
{privacy}: https://okekedev.github.io/CoinConvert/privacy.html"""


LOCALIZATIONS["zh-Hant"] = _e("Tagwise：掃描價格", "相機貨幣換算器",
    "匯率,換算,台幣,港幣,美元,日圓,歐元,旅行,出國,計算機,菜單,購物,外幣,免稅",
    "在旅行？把相機對準價格標籤或菜單，立刻看到換算成你貨幣的價格。離線可用，無需帳號，無廣告。",
    _desc("把相機對準任何價格，立刻看到換算成你貨幣的金額。Tagwise 幫你讀取價格標籤、菜單和收據，不必手動輸入。",
          "自動設定當地貨幣", "只需選擇一次本國貨幣。旅行時，Tagwise 會偵測所在國家並自動設定當地貨幣。",
          "150 多種貨幣 · 離線可用", "匯率儲存在手機上，在飛機上或沒有網路時也能使用。",
          "隱私", "掃描在裝置上完成，不會儲存或上傳任何照片。無需帳號，無廣告，無追蹤。",
          "TAGWISE PRO", "每週或每月方案可免費試用 3 天，也可一次購買終身版。訂閱會自動續訂，除非在當期結束前至少 24 小時取消；可在帳號設定中管理。",
          "使用條款", "隱私權政策"),
    "Real Time Currency Conversion 現已更名為 Tagwise：全新設計、自動設定當地貨幣、計算機和掃描器整合在同一畫面，匯率更新更可靠。")

LOCALIZATIONS["nl-NL"] = _e("Tagwise: scan prijzen", "Valuta omrekenen met camera",
    "wisselkoers,valuta,euro,dollar,pond,reizen,vakantie,rekenmachine,menu,buitenland,koers,geld",
    "Op reis? Richt je camera op een prijskaartje of menu en zie de prijs meteen in je eigen valuta. Offline, zonder account, zonder advertenties.",
    _desc("Richt je camera op een prijs en zie hem meteen in je eigen valuta. Tagwise leest prijskaartjes, menu's en bonnetjes voor je, zonder typen.",
          "LOKALE VALUTA AUTOMATISCH", "Kies één keer je eigen valuta. Op reis herkent Tagwise het land en zet de lokale valuta voor je klaar.",
          "MEER DAN 150 VALUTA'S · WERKT OFFLINE", "Wisselkoersen staan op je telefoon, dus het werkt ook in het vliegtuig of zonder data.",
          "PRIVÉ", "Scannen gebeurt op je toestel. Er worden geen foto's opgeslagen of geüpload. Geen account, geen advertenties, geen tracking.",
          "TAGWISE PRO", "Probeer 3 dagen gratis met het week- of maandabonnement, of koop Levenslang in één keer. Abonnementen worden automatisch verlengd tenzij je ten minste 24 uur voor het einde van de periode opzegt; beheer ze in je accountinstellingen.",
          "Voorwaarden", "Privacy"),
    "Real Time Currency Conversion heet nu Tagwise: nieuw ontwerp, automatisch de lokale valuta, rekenmachine en scanner op één scherm, en wisselkoersen die goed bijwerken.")

LOCALIZATIONS["ru"] = _e("Tagwise: сканер цен", "Конвертер валют по камере",
    "курс,валюта,обмен,рубль,доллар,евро,путешествие,калькулятор,меню,заграница,деньги,туризм",
    "В поездке? Наведите камеру на ценник или меню — и сразу увидите цену в своей валюте. Работает офлайн, без аккаунта и рекламы.",
    _desc("Наведите камеру на любую цену — и сразу увидите её в своей валюте. Tagwise читает ценники, меню и чеки за вас, без ввода вручную.",
          "МЕСТНАЯ ВАЛЮТА АВТОМАТИЧЕСКИ", "Выберите свою валюту один раз. В поездке Tagwise определяет страну и ставит местную валюту сам.",
          "БОЛЕЕ 150 ВАЛЮТ · РАБОТАЕТ ОФЛАЙН", "Курсы хранятся на телефоне, поэтому всё работает в самолёте и без интернета.",
          "КОНФИДЕНЦИАЛЬНОСТЬ", "Сканирование происходит на устройстве. Фото не сохраняются и не загружаются. Без аккаунта, рекламы и отслеживания.",
          "TAGWISE PRO", "3 дня бесплатно в недельном или месячном плане, либо разовая покупка «Навсегда». Подписка продлевается автоматически, если не отменить её минимум за 24 часа до конца периода; управлять можно в настройках аккаунта.",
          "Условия", "Конфиденциальность"),
    "Real Time Currency Conversion теперь Tagwise: новый дизайн, автоматическая местная валюта, калькулятор и сканер на одном экране и надёжное обновление курсов.")

LOCALIZATIONS["tr"] = _e("Tagwise: fiyatları tara", "Kameralı döviz çevirici",
    "kur,döviz,lira,dolar,euro,seyahat,tatil,hesap makinesi,menü,yurt dışı,para,kambiyo",
    "Seyahatte misiniz? Kamerayı etikete veya menüye tutun, fiyatı anında kendi para biriminizde görün. Çevrimdışı, hesapsız, reklamsız.",
    _desc("Kamerayı herhangi bir fiyata tutun, anında kendi para biriminizde görün. Tagwise etiketleri, menüleri ve fişleri sizin için okur; yazmanıza gerek yok.",
          "YEREL PARA BİRİMİ OTOMATİK", "Ana para biriminizi bir kez seçin. Seyahatte Tagwise ülkeyi algılar ve yerel para birimini sizin için ayarlar.",
          "150'DEN FAZLA PARA BİRİMİ · ÇEVRİMDIŞI ÇALIŞIR", "Kurlar telefonunuzda saklanır; uçakta veya internet olmadan da çalışır.",
          "GİZLİLİK", "Tarama cihazınızda yapılır. Hiçbir fotoğraf kaydedilmez veya yüklenmez. Hesap, reklam ve takip yok.",
          "TAGWISE PRO", "Haftalık veya aylık planla 3 gün ücretsiz deneyin ya da Ömür Boyu'yu tek seferde satın alın. Abonelikler, dönem bitmeden en az 24 saat önce iptal edilmezse otomatik yenilenir; hesap ayarlarından yönetebilirsiniz.",
          "Koşullar", "Gizlilik"),
    "Real Time Currency Conversion artık Tagwise: yeni tasarım, otomatik yerel para birimi, tek ekranda hesap makinesi ve tarayıcı, güvenilir kur güncellemeleri.")

LOCALIZATIONS["ar-SA"] = _e("Tagwise: امسح الأسعار", "محول العملات بالكاميرا",
    "صرف,عملة,ريال,دولار,يورو,سفر,سياحة,حاسبة,قائمة,الخارج,أسعار,تحويل",
    "مسافر؟ وجّه الكاميرا إلى بطاقة السعر أو قائمة الطعام وشاهد السعر فورًا بعملتك. يعمل دون اتصال، بلا حساب، بلا إعلانات.",
    _desc("وجّه الكاميرا إلى أي سعر وشاهده فورًا بعملتك. يقرأ Tagwise بطاقات الأسعار وقوائم الطعام والإيصالات نيابةً عنك، دون كتابة.",
          "العملة المحلية تلقائيًا", "اختر عملتك مرة واحدة. أثناء السفر يتعرف Tagwise على البلد ويضبط العملة المحلية لك.",
          "أكثر من 150 عملة · يعمل دون اتصال", "تُحفظ أسعار الصرف على هاتفك، فيعمل على متن الطائرة أو دون بيانات.",
          "الخصوصية", "يتم المسح على جهازك. لا تُحفظ أي صور ولا تُرفع. بلا حساب، بلا إعلانات، بلا تتبع.",
          "TAGWISE PRO", "جرّب مجانًا لمدة 3 أيام مع الخطة الأسبوعية أو الشهرية، أو اشترِ مدى الحياة بدفعة واحدة. تتجدد الاشتراكات تلقائيًا ما لم تُلغَ قبل 24 ساعة على الأقل من نهاية الفترة؛ يمكنك إدارتها من إعدادات حسابك.",
          "الشروط", "الخصوصية"),
    "أصبح Real Time Currency Conversion الآن Tagwise: تصميم جديد، وعملة محلية تلقائية، والحاسبة والماسح في شاشة واحدة، وتحديث موثوق لأسعار الصرف.")

LOCALIZATIONS["th"] = _e("Tagwise: สแกนราคา", "แปลงสกุลเงินด้วยกล้อง",
    "อัตราแลกเปลี่ยน,สกุลเงิน,บาท,ดอลลาร์,ยูโร,เที่ยว,ต่างประเทศ,เครื่องคิดเลข,เมนู,แลกเงิน",
    "เดินทางอยู่ใช่ไหม? ส่องกล้องไปที่ป้ายราคาหรือเมนู แล้วเห็นราคาเป็นสกุลเงินของคุณทันที ใช้ออฟไลน์ได้ ไม่ต้องมีบัญชี ไม่มีโฆษณา",
    _desc("ส่องกล้องไปที่ราคาใดก็ได้ แล้วเห็นเป็นสกุลเงินของคุณทันที Tagwise อ่านป้ายราคา เมนู และใบเสร็จให้คุณ ไม่ต้องพิมพ์",
          "ตั้งสกุลเงินท้องถิ่นอัตโนมัติ", "เลือกสกุลเงินหลักของคุณครั้งเดียว เมื่อเดินทาง Tagwise จะตรวจจับประเทศและตั้งสกุลเงินท้องถิ่นให้",
          "กว่า 150 สกุลเงิน · ใช้ออฟไลน์ได้", "อัตราแลกเปลี่ยนเก็บไว้ในโทรศัพท์ จึงใช้ได้บนเครื่องบินหรือตอนไม่มีเน็ต",
          "ความเป็นส่วนตัว", "การสแกนทำบนอุปกรณ์ ไม่มีการบันทึกหรืออัปโหลดรูปภาพ ไม่ต้องมีบัญชี ไม่มีโฆษณา ไม่มีการติดตาม",
          "TAGWISE PRO", "ทดลองใช้ฟรี 3 วันกับแผนรายสัปดาห์หรือรายเดือน หรือซื้อแบบตลอดชีพครั้งเดียว การสมัครสมาชิกจะต่ออายุอัตโนมัติ เว้นแต่ยกเลิกอย่างน้อย 24 ชั่วโมงก่อนสิ้นสุดรอบ จัดการได้ในการตั้งค่าบัญชี",
          "ข้อกำหนด", "ความเป็นส่วนตัว"),
    "Real Time Currency Conversion เปลี่ยนเป็น Tagwise แล้ว: ดีไซน์ใหม่ ตั้งสกุลเงินท้องถิ่นอัตโนมัติ เครื่องคิดเลขและสแกนเนอร์ในหน้าเดียว และอัปเดตอัตราแลกเปลี่ยนได้แม่นยำขึ้น")

LOCALIZATIONS["id"] = _e("Tagwise: pindai harga", "Konversi mata uang kamera",
    "kurs,valas,rupiah,dolar,euro,liburan,wisata,kalkulator,menu,luar negeri,tukar,uang",
    "Sedang bepergian? Arahkan kamera ke label harga atau menu dan lihat harganya langsung dalam mata uangmu. Offline, tanpa akun, tanpa iklan.",
    _desc("Arahkan kamera ke harga apa pun dan langsung lihat dalam mata uangmu. Tagwise membaca label harga, menu, dan struk untukmu, tanpa mengetik.",
          "MATA UANG LOKAL OTOMATIS", "Pilih mata uang utamamu sekali saja. Saat bepergian, Tagwise mendeteksi negara dan mengatur mata uang lokal untukmu.",
          "150+ MATA UANG · BISA OFFLINE", "Kurs disimpan di ponsel, jadi tetap berfungsi di pesawat atau tanpa data.",
          "PRIVASI", "Pemindaian terjadi di perangkat. Tidak ada foto yang disimpan atau diunggah. Tanpa akun, tanpa iklan, tanpa pelacakan.",
          "TAGWISE PRO", "Coba gratis 3 hari dengan paket mingguan atau bulanan, atau beli Seumur Hidup sekali bayar. Langganan diperpanjang otomatis kecuali dibatalkan minimal 24 jam sebelum periode berakhir; kelola di pengaturan akun.",
          "Ketentuan", "Privasi"),
    "Real Time Currency Conversion kini menjadi Tagwise: desain baru, mata uang lokal otomatis, kalkulator dan pemindai dalam satu layar, dan kurs yang diperbarui dengan andal.")

LOCALIZATIONS["pt-PT"] = _e("Tagwise: digitaliza preços", "Conversor de moedas",
    "câmbio,moeda,euro,dólar,libra,viagem,férias,calculadora,câmara,menu,estrangeiro,taxa",
    "Em viagem? Aponta a câmara a uma etiqueta ou menu e vê o preço logo na tua moeda. Sem ligação, sem conta, sem anúncios.",
    _desc("Aponta a câmara a qualquer preço e vê-o logo na tua moeda. O Tagwise lê etiquetas, menus e talões por ti, sem escrever nada.",
          "MOEDA LOCAL AUTOMÁTICA", "Escolhe a tua moeda uma vez. Em viagem, o Tagwise deteta o país e define a moeda local por ti.",
          "MAIS DE 150 MOEDAS · FUNCIONA SEM LIGAÇÃO", "As taxas ficam guardadas no telemóvel, por isso funciona no avião ou sem dados.",
          "PRIVACIDADE", "A digitalização é feita no dispositivo. Nenhuma foto é guardada ou enviada. Sem conta, sem anúncios, sem rastreio.",
          "TAGWISE PRO", "Experimenta grátis durante 3 dias com o plano semanal ou mensal, ou compra o Vitalício com um único pagamento. As subscrições renovam automaticamente, salvo cancelamento pelo menos 24 horas antes do fim do período; gere-as nas definições da conta.",
          "Termos", "Privacidade"),
    "O Real Time Currency Conversion passa a chamar-se Tagwise: novo design, moeda local automática, calculadora e digitalizador num só ecrã e taxas que atualizam corretamente.")
