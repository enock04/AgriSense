import '../models/models.dart';

class MockData {
  MockData._();

  // ── Crops ──────────────────────────────────────────────────────────────────
  static const List<Crop> allCrops = [
    Crop(id: 'maize',     name: 'Maize',     kinyarwanda: 'Ibigori',    emoji: '🌽'),
    Crop(id: 'beans',     name: 'Beans',     kinyarwanda: 'Ibishyimbo', emoji: '🫘'),
    Crop(id: 'potato',    name: 'Potato',    kinyarwanda: 'Ibirayi',    emoji: '🥔'),
    Crop(id: 'tomato',    name: 'Tomato',    kinyarwanda: 'Inyanya',    emoji: '🍅'),
    Crop(id: 'sorghum',   name: 'Sorghum',   kinyarwanda: 'Amashaza',   emoji: '🌾'),
    Crop(id: 'groundnut', name: 'Groundnut', kinyarwanda: 'Akaranga',   emoji: '🥜'),
    Crop(id: 'cassava',   name: 'Cassava',   kinyarwanda: 'Imyumbati',  emoji: '🌿'),
    Crop(id: 'onion',     name: 'Onion',     kinyarwanda: 'Iyeri',      emoji: '🧅'),
    Crop(id: 'soybean',   name: 'Soybean',   kinyarwanda: 'Sosiyeti',   emoji: '🌱'),
    Crop(id: 'sweet_potato', name: 'Sweet Potato', kinyarwanda: 'Ibijumba', emoji: '🍠'),
    Crop(id: 'banana',    name: 'Banana',    kinyarwanda: 'Umunyano',   emoji: '🍌'),
    Crop(id: 'coffee',    name: 'Coffee',    kinyarwanda: 'Ikawa',      emoji: '☕'),
  ];

  // ── Districts ──────────────────────────────────────────────────────────────
  static const List<Map<String, String>> districts = [
    {'name': 'Musanze',    'province': 'Northern Province · Amajyaruguru'},
    {'name': 'Nyagatare',  'province': 'Eastern Province · Iburasirazuba'},
    {'name': 'Huye',       'province': 'Southern Province · Amajyepfo'},
    {'name': 'Rubavu',     'province': 'Western Province · Iburengerazuba'},
    {'name': 'Kamonyi',    'province': 'Southern Province · Amajyepfo'},
    {'name': 'Gasabo',     'province': 'Kigali City · Umujyi wa Kigali'},
    {'name': 'Kicukiro',   'province': 'Kigali City · Umujyi wa Kigali'},
    {'name': 'Nyarugenge', 'province': 'Kigali City · Umujyi wa Kigali'},
    {'name': 'Ruhango',    'province': 'Southern Province · Amajyepfo'},
    {'name': 'Muhanga',    'province': 'Southern Province · Amajyepfo'},
    {'name': 'Rulindo',    'province': 'Northern Province · Amajyaruguru'},
    {'name': 'Nyabihu',    'province': 'Western Province · Iburengerazuba'},
    {'name': 'Bugesera',   'province': 'Eastern Province · Iburasirazuba'},
    {'name': 'Ngoma',      'province': 'Eastern Province · Iburasirazuba'},
    {'name': 'Kirehe',     'province': 'Eastern Province · Iburasirazuba'},
    {'name': 'Kayonza',    'province': 'Eastern Province · Iburasirazuba'},
    {'name': 'Rwamagana',  'province': 'Eastern Province · Iburasirazuba'},
    {'name': 'Burera',     'province': 'Northern Province · Amajyaruguru'},
    {'name': 'Gakenke',    'province': 'Northern Province · Amajyaruguru'},
    {'name': 'Gicumbi',    'province': 'Northern Province · Amajyaruguru'},
    {'name': 'Karongi',    'province': 'Western Province · Iburengerazuba'},
    {'name': 'Ngororero',  'province': 'Western Province · Iburengerazuba'},
    {'name': 'Nyamasheke', 'province': 'Western Province · Iburengerazuba'},
    {'name': 'Rusizi',     'province': 'Western Province · Iburengerazuba'},
    {'name': 'Rutsiro',    'province': 'Western Province · Iburengerazuba'},
    {'name': 'Gisagara',   'province': 'Southern Province · Amajyepfo'},
    {'name': 'Nyamagabe',  'province': 'Southern Province · Amajyepfo'},
    {'name': 'Nyanza',     'province': 'Southern Province · Amajyepfo'},
    {'name': 'Nyaruguru',  'province': 'Southern Province · Amajyepfo'},
    {'name': 'Ruhango',    'province': 'Southern Province · Amajyepfo'},
  ];

  // ── Weather (Good conditions) ──────────────────────────────────────────────
  static const WeatherData goodWeather = WeatherData(
    district: 'Musanze', province: 'Northern Province',
    temperature: 24, feelsLike: 22, humidity: 68,
    rainChance: 0.12, windSpeed: 14, uvIndex: 5,
    conditionEmoji: '⛅', status: WeatherStatus.good,
    advisoryText: 'Excellent conditions for field work. Low rainfall risk with good soil moisture — ideal for planting maize and beans.',
    advisoryKin: 'Ibihe ni byiza cyane byo gukorera mu mirima. Hari ubushuhe buke bwo kuvura — birahagije gutera ibigori n\'ibishyimbo.',
    hasSevereAlert: false,
    forecast: [
      ForecastDay(dayLabel: 'Today', weatherEmoji: '⛅', tempCelsius: 24, actionWord: 'PLANT',    status: WeatherStatus.good,    rainChance: 0.12),
      ForecastDay(dayLabel: 'Tue',   weatherEmoji: '🌤',  tempCelsius: 26, actionWord: 'PLANT',    status: WeatherStatus.good,    rainChance: 0.08),
      ForecastDay(dayLabel: 'Wed',   weatherEmoji: '⛈',  tempCelsius: 18, actionWord: 'WAIT',     status: WeatherStatus.caution, rainChance: 0.75),
      ForecastDay(dayLabel: 'Thu',   weatherEmoji: '🌧',  tempCelsius: 17, actionWord: 'WAIT',     status: WeatherStatus.caution, rainChance: 0.82),
      ForecastDay(dayLabel: 'Fri',   weatherEmoji: '🌦',  tempCelsius: 21, actionWord: 'IRRIGATE', status: WeatherStatus.good,    rainChance: 0.30),
      ForecastDay(dayLabel: 'Sat',   weatherEmoji: '☀',  tempCelsius: 27, actionWord: 'HARVEST',  status: WeatherStatus.good,    rainChance: 0.05),
      ForecastDay(dayLabel: 'Sun',   weatherEmoji: '☀',  tempCelsius: 28, actionWord: 'HARVEST',  status: WeatherStatus.good,    rainChance: 0.04),
    ],
  );

  // ── Weather (Severe alert) ─────────────────────────────────────────────────
  static const WeatherData severeWeather = WeatherData(
    district: 'Nyagatare', province: 'Eastern Province',
    temperature: 15, feelsLike: 12, humidity: 92,
    rainChance: 0.95, windSpeed: 42, uvIndex: 1,
    conditionEmoji: '🌩', status: WeatherStatus.severe,
    advisoryText: 'SEVERE: Do NOT enter fields today. Flash flood risk is extremely high. Stay indoors and secure your crops.',
    advisoryKin: 'INGARUKA NZITO: Ntugire akazi ko mu mirima uyu munsi. Hari ingaruka z\'ibyondo bikabije. Gumana mu nzu urinze ibigori byawe.',
    hasSevereAlert: true,
    alertTitle: '🚨 Flash Flood Warning · Impanuka y\'Ibyondo',
    alertBody: 'Nyagatare & Musanze districts — Avoid ALL field work. Roads may be impassable.',
    forecast: [
      ForecastDay(dayLabel: 'Today', weatherEmoji: '🌩',  tempCelsius: 15, actionWord: 'PROTECT', status: WeatherStatus.severe,  rainChance: 0.95),
      ForecastDay(dayLabel: 'Tue',   weatherEmoji: '🌧',  tempCelsius: 16, actionWord: 'WAIT',    status: WeatherStatus.caution, rainChance: 0.70),
      ForecastDay(dayLabel: 'Wed',   weatherEmoji: '🌦',  tempCelsius: 19, actionWord: 'WAIT',    status: WeatherStatus.caution, rainChance: 0.45),
      ForecastDay(dayLabel: 'Thu',   weatherEmoji: '⛅',  tempCelsius: 22, actionWord: 'PLANT',   status: WeatherStatus.good,    rainChance: 0.15),
      ForecastDay(dayLabel: 'Fri',   weatherEmoji: '☀',  tempCelsius: 25, actionWord: 'HARVEST', status: WeatherStatus.good,    rainChance: 0.05),
      ForecastDay(dayLabel: 'Sat',   weatherEmoji: '☀',  tempCelsius: 26, actionWord: 'HARVEST', status: WeatherStatus.good,    rainChance: 0.04),
      ForecastDay(dayLabel: 'Sun',   weatherEmoji: '🌤',  tempCelsius: 24, actionWord: 'PLANT',   status: WeatherStatus.good,    rainChance: 0.12),
    ],
  );

  // ── Lessons ────────────────────────────────────────────────────────────────
  static const List<Lesson> lessons = [
    Lesson(
      id: 'l1', emoji: '🌽', cropTag: 'Maize', topicTag: 'Planting',
      level: LessonLevel.beginner,
      formats: [LessonFormat.audio, LessonFormat.text],
      durationMinutes: 8, progress: 1.0, isDownloaded: true,
      title: 'Maize Planting & Spacing Guide',
      titleKin: 'Ingamba yo gutera ibigori',
      description: 'Learn the correct row spacing, planting depth, and certified seed selection for maximum maize yield in Rwanda\'s conditions. Covers both Season A and Season B planting windows.',
      descriptionKin: 'Menya uburyo bwo gutera ibigori neza kugira ngo ubone imyaka myiza. Birakubiyemo igihe cy\'imvura A na B.',
    ),
    Lesson(
      id: 'l2', emoji: '🌿', cropTag: 'Soil Health', topicTag: 'Soil',
      level: LessonLevel.intermediate,
      formats: [LessonFormat.video, LessonFormat.audio, LessonFormat.text],
      durationMinutes: 12, progress: 0.4,
      title: 'Composting for Better Soil',
      titleKin: 'Gukora kompositi yo kunoza ubutaka',
      description: 'Composting transforms organic farm waste into nutrient-rich fertilizer. This lesson shows you how to build, manage, and apply compost to dramatically improve your soil quality.',
      descriptionKin: 'Gukora kompositi bihinduza imyuzure mu ifumbire nziza cyane. Izi nyigisho ziraguha uburyo bwo kubaka no gucunga umuzinga wa kompositi.',
    ),
    Lesson(
      id: 'l3', emoji: '🐛', cropTag: 'Pest Control', topicTag: 'Pests',
      level: LessonLevel.all, formats: [LessonFormat.audio, LessonFormat.text],
      durationMinutes: 10, progress: 0.0, isNew: true,
      title: 'Fall Armyworm: Identify & Control',
      titleKin: 'Kumenya no kurwanya inzoka z\'ibigori',
      description: 'Fall armyworm is one of the most destructive pests for maize crops in East Africa. Learn to spot early warning signs, understand its lifecycle, and apply the most effective — and affordable — control measures.',
      descriptionKin: 'Inzoka ya Fall armyworm ni imwe mu ndwara zikomeye z\'ibigori mu Afurika y\'Iburasirazuba. Menya ibimenyetso bya mbere no gukoresha ibiganiro by\'ugutabara.',
    ),
    Lesson(
      id: 'l4', emoji: '🛡', cropTag: 'Climate-Smart', topicTag: 'Climate',
      level: LessonLevel.beginner, formats: [LessonFormat.text, LessonFormat.audio],
      durationMinutes: 7, progress: 0.0, isNew: true,
      title: 'Protecting Crops from Heavy Rain',
      titleKin: 'Kurinda imyaka igihe cy\'imvura nini',
      description: 'Heavy rains and flash floods are the leading cause of crop loss in Rwanda. This lesson teaches practical drainage techniques, raised bed construction, and mulching strategies to protect your harvest.',
      descriptionKin: 'Imvura nini n\'ibyondo ni imwe mu mpamvu nyinshi zo gutakaza imyaka mu Rwanda. Izi nyigisho zigufundisha uburyo bwo gukora imiyoboro, kubaka uturima tureremereye, no gukoresha ibikuta by\'ubutaka.',
    ),
    Lesson(
      id: 'l5', emoji: '💰', cropTag: 'Business', topicTag: 'Finance',
      level: LessonLevel.beginner, formats: [LessonFormat.audio, LessonFormat.text],
      durationMinutes: 9, progress: 0.0, isWomensPathway: true,
      title: 'Women\'s Income & Savings Guide',
      titleKin: 'Amabwiriza y\'Amafaranga n\'Izigama ry\'Abagore',
      description: 'Practical guidance for women farmers on tracking farm income, managing savings with VSLAs, and accessing Rwanda\'s micro-finance services. Includes a simple record-keeping template.',
      descriptionKin: 'Amabwiriza y\'ikoranabuhanga ku bagore b\'abahinzi yo gukurikirana amafaranga y\'ubuhinzi, gucunga izigama na VSLA, no kubona serivisi z\'imari.',
    ),
    Lesson(
      id: 'l6', emoji: '🥬', cropTag: 'Vegetables', topicTag: 'Garden',
      level: LessonLevel.beginner, formats: [LessonFormat.video, LessonFormat.audio],
      durationMinutes: 8, progress: 0.0, isWomensPathway: true,
      title: 'Kitchen Garden Setup',
      titleKin: 'Gushinga Inzirakarima y\'Urugo',
      description: 'Set up a productive 3×3m kitchen garden to grow nutritious vegetables for your family and generate surplus income at local markets. Includes seasonal planting calendar for Rwanda.',
      descriptionKin: 'Shinga inzirakarima y\'uburyo bwa 3×3m kugira ngo ubeho imboga z\'intungamubiri kandi ugurisha ibisigaye ku isoko.',
    ),
    Lesson(
      id: 'l7', emoji: '🌧', cropTag: 'Climate-Smart', topicTag: 'Climate',
      level: LessonLevel.intermediate, formats: [LessonFormat.text],
      durationMinutes: 11, progress: 0.0, isNew: true,
      title: 'Drought-Resistant Farming Techniques',
      titleKin: 'Ubuhinzi budapfushwa n\'amapfa',
      description: 'Climate change is increasing drought frequency in Rwanda. Learn water conservation methods, drought-tolerant crop varieties, and irrigation techniques suited to smallholder farms.',
      descriptionKin: 'Impinduka z\'ibihe zirongera amapfa mu Rwanda. Menya uburyo bwo kubika amazi, inzuki z\'imbuto zihangana n\'amapfa, n\'ubunyunyuzi bw\'amazi.',
    ),
    Lesson(
      id: 'l8', emoji: '🥜', cropTag: 'Groundnut', topicTag: 'Planting',
      level: LessonLevel.beginner, formats: [LessonFormat.audio],
      durationMinutes: 6, progress: 0.0,
      title: 'Groundnut Production Guide',
      titleKin: 'Uburyo bwo guhinga akaranga',
      description: 'Groundnuts are a high-value crop with strong market demand in Rwanda. Learn optimal planting density, intercropping strategies with maize, pest management, and post-harvest storage.',
      descriptionKin: 'Akaranga ni imyaka y\'agaciro gakomeye ifite isoko ryiza mu Rwanda. Menya ubucucike bwo gutera, guhuza na ibigori, kurwanya ibyonnyi, no kubika nyuma yo gusarura.',
    ),
    Lesson(
      id: 'l9', emoji: '🌾', cropTag: 'Sorghum', topicTag: 'Planting',
      level: LessonLevel.intermediate, formats: [LessonFormat.audio, LessonFormat.text],
      durationMinutes: 9, progress: 0.0,
      title: 'Sorghum for Food & Income',
      titleKin: 'Amashaza y\'indyo n\'amafaranga',
      description: 'Sorghum is one of Rwanda\'s most resilient crops, thriving in dry conditions where maize struggles. Discover improved varieties, market linkages, and value addition opportunities including local brewing.',
      descriptionKin: 'Amashaza ni imwe mu myaka y\'u Rwanda ikomeye cyane, ikura neza aho amapfa agira uruhare. Menya inzuki nshya, isoko, n\'amahirwe yo kongera agaciro.',
    ),
    Lesson(
      id: 'l10', emoji: '🐄', cropTag: 'Livestock', topicTag: 'Animal',
      level: LessonLevel.beginner, formats: [LessonFormat.video, LessonFormat.audio],
      durationMinutes: 14, progress: 0.0, isNew: true,
      title: 'Integrated Crop-Livestock Farming',
      titleKin: 'Guhuza ubuhinzi n\'ubworozi',
      description: 'Learn how combining crops with small livestock — goats, rabbits, and chickens — creates a circular system: manure feeds the soil, crops feed the animals, animals generate income year-round.',
      descriptionKin: 'Menya uburyo guhuza imyaka n\'amatungo make — inzuki, inkwavu, n\'inkoko — bibyara uburyo bugendana: amase agaburira ubutaka, imyaka igaburira amatungo, amatungo agatanga amafaranga muri rusange.',
    ),
  ];

  // ── Tips of the Day (rotated daily) ───────────────────────────────────────
  static const List<Map<String, String>> tipsOfDay = [
    {
      'title':   'Space maize rows 75 cm apart',
      'titleKin':'Imbanzi y\'inzira z\'ibigori: cm 75',
      'body':    'Proper row spacing improves air circulation and reduces fungal disease risk by up to 40%. Plant seeds 25 cm apart within rows.',
      'bodyKin': 'Ikirangantego cy\'inzira gikuraho ikirere kandi gikabanya ingaruka z\'indwara z\'ubuhumyi.',
      'emoji':   '🌽',
    },
    {
      'title':   'Water in the early morning',
      'titleKin':'Nyunyuza vuba mu gitondo',
      'body':    'Watering between 6–8 AM reduces evaporation by up to 60% and prevents fungal diseases that thrive in wet evening conditions.',
      'bodyKin': 'Kuyunyuza hagati ya 6–8 mu gitondo bigabanya impogamizi y\'amazi no kubuza indwara z\'ubuhumyi.',
      'emoji':   '💧',
    },
    {
      'title':   'Apply compost 2 weeks before planting',
      'titleKin':'Shyira kompositi ibyumweru 2 mbere yo gutera',
      'body':    'Compost applied 2 weeks before planting has time to integrate with soil, making nutrients more available to seedling roots.',
      'bodyKin': 'Kompositi ishyirwa ibyumweru 2 mbere yo gutera igira igihe cyo gufatana n\'ubutaka.',
      'emoji':   '🌿',
    },
    {
      'title':   'Intercrop beans with maize',
      'titleKin':'Huza ibishyimbo n\'ibigori',
      'body':    'Intercropping beans with maize fixes nitrogen in the soil, reducing fertilizer needs by up to 30% while increasing total yield per hectare.',
      'bodyKin': 'Guhuza ibishyimbo n\'ibigori bishyira azote mu butaka, bikagabanya ibikenewe by\'ifumbire.',
      'emoji':   '🫘',
    },
    {
      'title':   'Check for armyworm eggs at dawn',
      'titleKin':'Reba amagi y\'inzoka vuba mu gitondo',
      'body':    'Fall armyworm moths lay eggs at night. Check the whorls of young maize plants at dawn for egg masses — early detection saves your crop.',
      'bodyKin': 'Ibinyugunyugu bya Fall armyworm bitaga ijoro. Reba imbuto z\'ibigori bito vuba mu gitondo.',
      'emoji':   '🐛',
    },
  ];

  static Map<String, String> get tipOfDay {
    final index = DateTime.now().day % tipsOfDay.length;
    return tipsOfDay[index];
  }

  // ── Community Posts ────────────────────────────────────────────────────────
  static const List<CommunityPost> communityPosts = [
    CommunityPost(
      id: 'p1', userName: 'Gasana Jean-Pierre', userInitials: 'GJ',
      district: 'Musanze', upvotes: 24, replyCount: 8,
      timeAgo: '2 hours ago', timeAgoKin: 'Amasaha 2 ashize',
      question: 'My maize leaves are turning yellow from the bottom — could this be nitrogen deficiency or overwatering? This started 3 days after planting.',
      questionKin: 'Amakabi y\'ibigori yanjye arahuha uhereye hasi — bishobora kuba ubunure bwa azote buke cyangwa amazi menshi? Bitangiriye iminsi 3 nyuma yo gutera.',
    ),
    CommunityPost(
      id: 'p2', userName: 'Mukamana Vestine', userInitials: 'MV',
      district: 'Huye', upvotes: 17, replyCount: 5,
      timeAgo: '4 hours ago', timeAgoKin: 'Amasaha 4 ashize',
      question: 'What is the best time to harvest beans in the Southern Province this season A? I am seeing pods turning brown.',
      questionKin: 'Ni ryari igihe cyiza cyo gusarura ibishyimbo mu ntara y\'amajyepfo uyu mwaka wa A? Ndeba inzunguru zihinduka urukaka.',
    ),
    CommunityPost(
      id: 'p3', userName: 'Habimana Pierre', userInitials: 'HP',
      district: 'Nyagatare', upvotes: 31, replyCount: 12,
      timeAgo: '1 day ago', timeAgoKin: 'Umunsi 1 ushize',
      question: 'Has anyone tried drip irrigation for tomatoes in the Eastern Province? I want to expand my 0.5 ha plot and wondering if the investment is worth it.',
      questionKin: 'Umuntu n\'umwe wagerageje ubunyunyuzi bw\'amazi ku nyanya mu ntara y\'iburasirazuba? Ndashaka gukuza inzuri yanjye ya 0.5 ha.',
    ),
    CommunityPost(
      id: 'p4', userName: 'Uwimana Claudette', userInitials: 'UC',
      district: 'Gasabo', upvotes: 9, replyCount: 3,
      timeAgo: '2 days ago', timeAgoKin: 'Iminsi 2 ishize',
      question: 'Where can I sell my surplus sorghum in Kigali? I have about 200 kg from this season and want a fair price.',
      questionKin: 'Ni he nabona amasoko yo kugurisha amashaza yanjye muri Kigali? Mfite ngo kg 200 z\'iki gisekuru kandi nshaka igiciro cyiza.',
    ),
    CommunityPost(
      id: 'p5', userName: 'Ntwari Emmanuel', userInitials: 'NE',
      district: 'Rubavu', upvotes: 45, replyCount: 19,
      timeAgo: '3 days ago', timeAgoKin: 'Iminsi 3 ishize',
      question: 'After the heavy rains last week my Irish potato field has what looks like late blight — grey spots with white rings on the leaves. What should I spray?',
      questionKin: 'Nyuma y\'imvura nini y\'inshuti ishize, inzu yanjye y\'ibirayi ifite ibironda biremba na rimwe birimo ingano zera. Ni iki nakwasya?',
    ),
    CommunityPost(
      id: 'p6', userName: 'Ingabire Odette', userInitials: 'IO',
      district: 'Muhanga', upvotes: 14, replyCount: 6,
      timeAgo: '4 days ago', timeAgoKin: 'Iminsi 4 ishize',
      question: 'Can I still join a VSLA group mid-year? I want to start saving for next season\'s inputs.',
      questionKin: 'Nshobora kwinjira mu itsinda rya VSLA hagati y\'umwaka? Ndashaka gutangira kugurisha ibikenewe by\'igisekuru gikurikira.',
    ),
  ];
}
