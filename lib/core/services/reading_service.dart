import 'package:drift/drift.dart' show Value;
import 'package:xml/xml.dart';

import '../db/database.dart';
import 'api_client.dart';
import '../i18n/i18n.dart';

/// Okuma sayfası içerik kaynağı.
class FeedSource {
  const FeedSource({
    required this.id,
    required this.nameTr,
    required this.url,
    required this.descriptionTr,
    required this.technical,
  });

  final String id;
  final String nameTr;
  final String url;
  final String descriptionTr;

  /// true ise hekim/teknik okur (uzman modu).
  final bool technical;
}

/// DOĞRULANMIŞ RSS adresleri (23 Kasım 2026'da erişilebilir olanlar).
///
/// Not: kidney.org, kidneyfund.org, NIDDK ve Mayo Clinic için
/// makine ile okunabilir RSS adresi BULUNAMADI (404/403 döndüler).
/// Türk Nefroloji Derneği'nin de RSS akışı yok. Bu kaynaklar için
/// [kBuiltinArticles] içinde elle yazılmış, kaynak gösteren
/// başlangıç içerikleri bulunur.
const List<FeedSource> kVerifiedFeeds = [
  FeedSource(
    id: 'kidney_international',
    nameTr: 'Kidney International (KDIGO dergisi)',
    url: 'https://www.kidney-international.org/action/showFeed'
        '?type=etoc&feed=rss&jc=kint',
    descriptionTr: 'KDIGO kılavuzlarının yayımlandığı dergi. '
        'İçerik İngilizce ve tekniktir.',
    technical: true,
  ),
  FeedSource(
    id: 'nephjc',
    nameTr: 'NephJC (Nefroloji dergi kulübü)',
    url: 'https://nephjc.com/news?format=rss',
    descriptionTr: 'Yeni nefroloji çalışmalarının hekimler tarafından '
        'tartışıldığı özetler. İngilizce, teknik.',
    technical: true,
  ),
  FeedSource(
    id: 'kidney_research_uk',
    nameTr: 'Kidney Research UK',
    url: 'https://www.kidneyresearchuk.org/feed/',
    descriptionTr: 'Böbrek vakfı haberleri ve hasta hikâyeleri. '
        'İngilizce, genel okur için.',
    technical: false,
  ),
];

/// Elle yazılmış, kaynak gösteren başlangıç içerikleri.
///
/// RSS erişilemediğinde veya çevrimdışıyken Okuma sayfası boş kalmasın.
/// Her maddenin kaynağı [sourceName] ve [link] ile verilir.
const List<({
  String title,
  String summary,
  String body,
  String sourceName,
  String link,
})> kBuiltinArticles = [
  (
    title: 'Potasyumu azaltmanın pratik yolları',
    summary: 'Haşlama suyunu dökmek, sebzedeki potasyumu belirgin '
        'ölçüde azaltır.',
    body: 'Patates, havuç ve kuru baklagilleri küçük parçalara '
        'bölüp bol suda haşlamak ve haşlama suyunu DÖKMEK, '
        'besindeki potasyumun önemli bir kısmını uzaklaştırır. '
        'Suyu çorbaya katmak bu kazancı geri alır.\n\n'
        'Dikkat edilecekler:\n'
        '• Domates salçası, kuru kayısı/üzüm, muz, avokado ve kavun '
        'yüksek potasyumludur.\n'
        '• "Light tuz" veya "az sodyumlu tuz" ürünleri POTASYUM '
        'KLORÜR içerir ve böbrek hastasında tehlikeli olabilir. '
        'Etiketi oku.\n'
        '• Çiğ sebzeyi haşlanmışla değiştirmek porsiyonu korurken '
        'potasyumu düşürür.\n\n'
        'KDOQI 2020, diyet potasyumunun SABİT bir sayıya göre değil, '
        'serum potasyum sonucuna göre bireyselleştirilmesini önerir. '
        'Kendi hedefini doktorun belirler.',
    sourceName: 'KDOQI 2020 Nutrition in CKD',
    link: 'https://www.ajkd.org/article/S0272-6386(20)30726-5/fulltext',
  ),
  (
    title: 'Gizli sodyum nerede saklanıyor?',
    summary: 'Tuzluk, günlük sodyumun küçük bir kısmıdır; '
        'büyük kısmı işlenmiş gıdadan gelir.',
    body: 'KDIGO 2024, böbrek hastalığında günlük sodyumun 2 gramın '
        '(yaklaşık 5 gram tuz) altında tutulmasını önerir (öneri 2C). '
        'Türk mutfağında sodyumun ana kaynakları:\n\n'
        '• Salça ve hazır soslar\n'
        '• Turşu, salamura zeytin, tursu suyu\n'
        '• Beyaz peynir ve tulum peyniri (salamura)\n'
        '• Sucuk, salam, pastırma, kavurma\n'
        '• Hazır çorba, bulyon küpü, hazır baharat karışımları\n'
        '• Ekmek (porsiyon başına az ama gün içinde toplanır)\n'
        '• Maden suyu ve soda (bazı markalarda sodyum yüksek)\n\n'
        'Lezzet için tuz yerine: limon, sirke, kuru soğan/sarımsak '
        'tozu (tuzsuz olanı), kekik, kimyon, nane, kişniş, '
        'tarçın, kara biber.\n\n'
        'ÖNEMLİ İSTİSNA: Tuz kaybettiren nefropatide sodyum '
        'kısıtlaması genellikle UYGUN DEĞİLDİR. Kendi durumunu '
        'doktorunla değerlendir.',
    sourceName: 'KDIGO 2024 CKD Kılavuzu',
    link: 'https://www.kidney-international.org/article/S0085-2538(23)00766-4/fulltext',
  ),
  (
    title: 'Ağrı kesici seçerken',
    summary: 'NSAİİ\'ler böbreğe giden kan akımını azaltır; '
        'CKD\'de kaçınılması önerilir.',
    body: 'National Kidney Foundation, böbrek hastalarının '
        'NSAİİ\'lerden kaçınmasını, özellikle eGFR 60\'ın altındaysa, '
        'öneriyor.\n\n'
        'Türkiye\'de yaygın NSAİİ\'ler ve ticari adları:\n'
        '• İbuprofen — Brufen, Nurofen, Dolven, Advil\n'
        '• Diklofenak — Voltaren, Dikloron, Cataflam\n'
        '• Naproksen — Apranax, Aprol, Synax\n'
        '• Deksketoprofen — Arveles, Desalgin\n'
        '• Etodolak — Etol, Tadolak\n'
        '• Meloksikam — Melox, Mobic, Zeloxim\n'
        '• Nimesulid — Nimes, Mesulid\n\n'
        'Jel ve krem formları da sayılır.\n\n'
        'ÖNEMLİ: Kalp hastalığı için hekimin önerdiği DÜŞÜK DOZ '
        'aspirin bu uyarının dışındadır ve kendi başına '
        'kesilmemelidir.\n\n'
        'Bu liste kapsamlı değildir. Her yeni ağrı kesiciyi '
        'hekiminle konuş.',
    sourceName: 'National Kidney Foundation',
    link: 'https://www.kidney.org/kidney-topics/pain-medicines-and-kidney-disease',
  ),
  (
    title: 'Diyaliz arası kilo artışı neden önemli?',
    summary: 'Hedef, kuru ağırlığın %4-4,5\'inden az artış.',
    body: 'İki diyaliz seansı arasında vücutta biriken sıvı, '
        'tartıdaki artış olarak görünür. Literatür, bu artışın '
        '(IDWG) kuru vücut ağırlığının %4,0-4,5\'inden AZ '
        'olmasını hedefler.\n\n'
        'Örnek: kuru ağırlığı 70 kg olan biri için %4 = 2,8 kg.\n\n'
        'Fazla artış şu sorunlara yol açar:\n'
        '• Yüksek tansiyon ve kalp yüklenmesi\n'
        '• Seans sırasında daha agresif ultrafiltrasyon, buna bağlı '
        'kramp ve tansiyon düşmesi\n'
        '• Nefes darlığı, bacaklarda ödem\n\n'
        'Artışın ana belirleyicisi SU değil SODYUMDUR: tuzlu yemek '
        'susuzluk yaratır ve sıvıyı vücutta tutar. Sodyumu azaltmak, '
        'sıvıyı kısıtlamaktan daha kolay sonuç verir.\n\n'
        'Sıvı limiti hastaya göre belirlenir; aynı literatür sabit '
        'hacim yerine bireysel reçeteyi savunur.',
    sourceName: 'Nutrients 2025 derlemesi (PMC11942859)',
    link: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC11942859/',
  ),
  (
    title: 'Fosfor: doğal mı, katkı maddesi mi?',
    summary: 'Katkı maddesi fosforu doğal fosfordan çok daha iyi emilir.',
    body: 'Fosforun emilimi kaynağına göre değişir:\n\n'
        '• Bitkisel fosfor (baklagil, tahıl): en az emilir '
        '(fitat biçiminde bağlı).\n'
        '• Hayvansal fosfor (et, süt, yumurta): orta düzeyde emilir.\n'
        '• KATKI MADDESİ fosforu (fosforik asit, fosfat tuzları): '
        'neredeyse tamamı emilir.\n\n'
        'Etikette şunları ara: fosforik asit, sodyum fosfat, '
        'kalsiyum fosfat, polifosfat, "E338-E343", "E450-E452".\n\n'
        'Yüksek katkı fosforu içeren ürünler: kola ve koyu renkli '
        'gazlı içecekler, işlenmiş et (sosis, salam, nugget), '
        'eritme/üçgen peynir, hazır kek ve bisküvi, dondurulmuş '
        'hazır yemek.\n\n'
        'KDIGO 2017 CKD-MBD, fosfat bağlayıcıların ÖNLEYİCİ amaçla '
        'değil, kalıcı/yükselen fosfat için kullanılmasını söyler. '
        'Hedef aralığı doktorun belirler.',
    sourceName: 'KDIGO 2017 CKD-MBD Kılavuz Güncellemesi',
    link: 'https://kdigo.org/wp-content/uploads/2017/02/2017-KDIGO-CKD-MBD-GL-Update.pdf',
  ),
  (
    title: 'Hangi belirtide hemen doktora / 112\'ye?',
    summary: 'Beklemeden değerlendirilmesi gereken belirtiler.',
    body: 'Aşağıdaki belirtilerde BEKLEMEDEN 112\'yi ara ya da '
        'en yakın acile git:\n\n'
        '• Göğüs ağrısı veya göğüste baskı\n'
        '• Ciddi nefes darlığı, yatarken nefes alamama\n'
        '• Bayılma veya bayılacak gibi olma\n'
        '• İdrarın belirgin azalması ya da tamamen kesilmesi\n'
        '• Ciddi kas güçsüzlüğü, bacaklarda güç kaybı\n'
        '• Çarpıntı veya düzensiz nabız\n'
        '• Bilinç bulanıklığı, aşırı uyku hâli\n'
        '• Durdurulamayan kusma\n'
        '• Konuşma güçlüğü, yüzün bir tarafının kayması\n'
        '• Diyaliz kateteri/fistül çevresinde ateş, kızarıklık, akıntı\n\n'
        'Hiperkalemi (yüksek potasyum) kas güçsüzlüğü ve kalp '
        'ritim bozukluğu yapabilir ve belirtisiz de seyredebilir — '
        'bu yüzden tahlil takvimini kaçırmamak önemlidir.\n\n'
        'Bu liste tıbbi tavsiye değildir; acil durumda karar '
        'beklemeden aramak yönünde olmalıdır.',
    sourceName: 'KDIGO potasyum konferansı + ACC/AHA 2017',
    link: 'https://kdigo.org/wp-content/uploads/2018/04/KDIGO-Potassium-Management-Final-publication.pdf',
  ),
];

class ReadingService {
  ReadingService({required this.api, required this.db});

  final ApiClient api;
  final AppDatabase db;

  /// Yerleşik içerikleri (bir kez) veritabanına yazar.
  Future<void> seedBuiltinArticles() async {
    final existing = await (db.select(db.articleRows)
          ..where((t) => t.origin.equals('builtin')))
        .get();
    if (existing.isNotEmpty) return;

    for (final a in kBuiltinArticles) {
      await db.into(db.articleRows).insert(
            ArticleRowsCompanion.insert(
              title: a.title,
              summary: Value(a.summary),
              body: Value(a.body),
              link: Value(a.link),
              sourceName: a.sourceName,
              origin: 'builtin',
              savedOffline: const Value(true),
            ),
          );
    }
  }

  /// RSS akışlarını çeker. Erişilemeyen kaynakları rapor eder.
  ///
  /// Sonuç: (eklenen madde sayısı, başarısız kaynak adları).
  Future<({int added, List<String> failedTr})> refreshFeeds({
    bool includeTechnical = true,
  }) async {
    var added = 0;
    final failed = <String>[];

    for (final feed in kVerifiedFeeds) {
      if (feed.technical && !includeTechnical) continue;
      try {
        final raw = await api.cachedGet(
          Uri.parse(feed.url),
          maxAge: const Duration(hours: 6),
        );
        final items = parseFeed(raw, feed.nameTr);
        for (final item in items.take(12)) {
          // Aynı bağlantı varsa tekrar eklemeyelim.
          final dupe = await (db.select(db.articleRows)
                ..where((t) => t.link.equals(item.link ?? ''))
                ..limit(1))
              .getSingleOrNull();
          if (dupe != null) continue;

          await db.into(db.articleRows).insert(
                ArticleRowsCompanion.insert(
                  title: item.title,
                  summary: Value(item.summary),
                  body: Value(item.summary),
                  link: Value(item.link),
                  sourceName: feed.nameTr,
                  origin: 'rss',
                  publishedAt: Value(item.publishedAt),
                  savedOffline: const Value(true),
                ),
              );
          added++;
        }
      } on ServiceFailure catch (e) {
        failed.add('${feed.nameTr} (${e.messageTr})');
      } on Object {
        failed.add(tf('{0} (içerik okunamadı)', [feed.nameTr]));
      }
    }

    return (added: added, failedTr: failed);
  }
}

/// RSS 2.0 ve RSS 1.0/RDF ile Atom akışlarını ayrıştırır.
///
/// SAF fonksiyon — test edilebilir.
List<({String title, String? summary, String? link, DateTime? publishedAt})>
    parseFeed(String xmlString, String sourceName) {
  final out =
      <({String title, String? summary, String? link, DateTime? publishedAt})>[];

  XmlDocument doc;
  try {
    doc = XmlDocument.parse(xmlString);
  } on XmlException {
    return out;
  }

  String? textOf(XmlElement parent, String name) {
    final el = parent.findElements(name).firstOrNull ??
        parent.descendantElements
            .where((e) => e.name.local == name)
            .firstOrNull;
    final t = el?.innerText.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  // RSS 2.0 / RSS 1.0: <item>; Atom: <entry>
  final items = [
    ...doc.findAllElements('item'),
    ...doc.findAllElements('entry'),
  ];

  for (final item in items) {
    final title = textOf(item, 'title');
    if (title == null) continue;

    var link = textOf(item, 'link');
    // Atom'da bağlantı href özniteliğindedir.
    if (link == null || link.isEmpty) {
      final linkEl = item.findElements('link').firstOrNull;
      link = linkEl?.getAttribute('href');
    }

    final summaryRaw = textOf(item, 'description') ??
        textOf(item, 'summary') ??
        textOf(item, 'content');

    final dateRaw = textOf(item, 'pubDate') ??
        textOf(item, 'date') ??
        textOf(item, 'published') ??
        textOf(item, 'updated');

    out.add((
      title: _stripHtml(title),
      summary: summaryRaw == null ? null : _truncate(_stripHtml(summaryRaw), 600),
      link: link,
      publishedAt: dateRaw == null ? null : parseFeedDate(dateRaw),
    ));
  }

  return out;
}

/// RFC 822 ve ISO 8601 tarihlerini çözer.
DateTime? parseFeedDate(String raw) {
  final iso = DateTime.tryParse(raw.trim());
  if (iso != null) return iso;

  // "Mon, 23 Nov 2026 11:55:00 GMT"
  final m = RegExp(
    r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
    r'\s+(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?',
  ).firstMatch(raw);
  if (m == null) return null;

  const months = {
    'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
    'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
  };
  return DateTime.utc(
    int.parse(m.group(3)!),
    months[m.group(2)!]!,
    int.parse(m.group(1)!),
    m.group(4) == null ? 0 : int.parse(m.group(4)!),
    m.group(5) == null ? 0 : int.parse(m.group(5)!),
    m.group(6) == null ? 0 : int.parse(m.group(6)!),
  );
}

String _stripHtml(String input) => input
    .replaceAll(RegExp(r'<[^>]*>'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _truncate(String s, int max) =>
    s.length <= max ? s : '${s.substring(0, max).trimRight()}…';
