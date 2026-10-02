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
