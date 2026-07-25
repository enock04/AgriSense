import 'package:flutter/material.dart';
import '../presentation/providers/app_provider.dart';
import 'package:provider/provider.dart';

// ── Extension for easy access ──────────────────────────────────────────────
extension AppStringsX on BuildContext {
  AppStrings get tr {
    final lang = read<AppProvider>().language;
    return AppStrings(lang);
  }
  AppStrings get trW {
    final lang = watch<AppProvider>().language;
    return AppStrings(lang);
  }
}

// ── All app strings in EN / RW / FR ───────────────────────────────────────

class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  bool get isRw => lang == 'rw';
  bool get isFr => lang == 'fr';

  /// Pick the right text from a bilingual model field.
  /// Falls back to [en] for French (content not translated).
  String langText(String en, String rw) => isRw ? rw : en;

  String _t(String en, String rw, String fr) {
    if (isRw) return rw;
    if (isFr) return fr;
    return en;
  }

  // ── Navigation ────────────────────────────────────────────────────────
  String get navHome      => _t('Home',      'Ahabanza',   'Accueil');
  String get navWeather   => _t('Weather',   'Ibihe',      'Météo');
  String get navLearn     => _t('Learn',     'Iga',        'Apprendre');
  String get navCommunity => _t('Community', 'Umuryango',  'Communauté');
  String get navProfile   => _t('Profile',   'Umwirondoro','Profil');

  // ── Home Screen ───────────────────────────────────────────────────────
  String get homeMuraho        => _t('Hello',             'Muraho',           'Bonjour');
  String get homeGoodMorning   => _t('Good morning',      'Mwaramutse',       'Bonjour');
  String get homeGoodAfternoon => _t('Good afternoon',    'Mwiriwe',          'Bon après-midi');
  String get homeGoodEvening   => _t('Good evening',      'Bwakeye',          'Bonsoir');
  String get homeForecast      => _t("Today's Forecast",  "Ibihe by'uyu munsi","Prévisions d'aujourd'hui");
  String get homeDetails       => _t('Details →',         'Amakuru →',        'Détails →');
  String get homeTodayTip      => _t("Today's Tip",       "Inama y'uyu munsi","Conseil du jour");
  String get homeLearning      => _t('Continue Learning', 'Komeza Kwiga',     "Continuer d'apprendre");
  String get homeAllLessons    => _t('All lessons →',     'Amasomo yose →',   'Toutes les leçons →');
  String get homeCommunity     => _t('Community',         'Umuryango',        'Communauté');
  String get homeSeeAll        => _t('See all →',         'Reba byose →',     'Tout voir →');
  String get homeStatusGood    => _t('🟢  GOOD · IN SEASON',    '🟢  BYIZA · MU GIHE',    '🟢  BON · EN SAISON');
  String get homeStatusCaution => _t('🟡  CAUTION · WARNING',   '🟡  WITONDERE · INGARUKA','🟡  ATTENTION · ALERTE');
  String get homeStatusSevere  => _t('🔴  SEVERE · DANGER',     '🔴  INGARUKA NZITO',      '🔴  SÉVÈRE · DANGER');

  // ── Weather Screen ────────────────────────────────────────────────────
  String get weatherTitle      => _t('Weather Advisory',  'Inama y\'Ibihe',    'Avis Météo');
  String get weatherAdvisory   => _t('Advisory · Inama',  'Inama',             'Avis');
  String get weather7Day       => _t("7-Day Forecast · Igenamigambi y'Iminsi 7",
                                     "Igenamigambi y'Iminsi 7",
                                     "Prévisions sur 7 jours");
  String get weatherChange     => _t('Change',            'Hindura',           'Changer');
  String get weatherSelect     => _t('Select District',   'Hitamo Akarere',    'Sélectionner le district');
  String get weatherHumidity   => _t('Humidity',          'Ubuhehere',         'Humidité');
  String get weatherRain       => _t('Rain',              'Imvura',            'Pluie');
  String get weatherWind       => _t('Wind',              'Umuyaga',           'Vent');

  // ── Learn Screen ──────────────────────────────────────────────────────
  String get learnTitle        => _t('Learn · Iga',       'Iga',               'Apprendre');
  String get learnCompleted    => _t('Completed',         'Byarangiye',        'Terminé');
  String get learnInProgress   => _t('In Progress',       'Birashoboka',       'En cours');
  String get learnNew          => _t('New',               'Bishya',            'Nouveau');
  String get learnWomens       => _t("Women's Pathway",   "Inzira y'Abagore",  "Parcours Femmes");
  String get learnWomensAvail  => _t('lessons available', 'amasomo aboneka',   'leçons disponibles');
  String get learnExplore      => _t('Explore',           'Shakisha',          'Explorer');
  String get learnSearch       => _t('Search lessons...', 'Shakisha amasomo...','Rechercher des leçons...');
  String get learnMinutes      => _t('min',               'min',               'min');
  String get learnCompleteBtn  => _t('Lesson Complete! ✓','Isomo ryarangiye ✓','Leçon terminée ✓');
  String get learnStartBtn     => _t('Start Lesson',      'Tangira Isomo',     'Commencer la leçon');
  String get learnContinueBtn  => _t('Continue',          'Komeza',            'Continuer');

  // ── Community Screen ──────────────────────────────────────────────────
  String get commTitle         => _t('Community · Umuryango', 'Umuryango',     'Communauté');
  String get commAsk           => _t('Ask · Baza',            'Baza',          'Demander');
  String get commFarmers       => _t('Farmers\nAbahinzi',     'Abahinzi',      'Agriculteurs');
  String get commQuestions     => _t('Questions\nIbibazo',    'Ibibazo',       'Questions');
  String get commDistricts     => _t('Districts\nAkarere',    'Akarere',       'Districts');
  String get commPostQuestion  => _t('Post Question',         'Tanga Ikibazo', 'Poser une question');
  String get commNoPostsYet    => _t('No posts yet. Be the first to ask!',
                                     'Nta bibazo bihari. Baza mbere!',
                                     'Pas encore de messages. Soyez le premier!');
  String get commAskTitle      => _t('Ask the Community',     'Baza Umuryango','Demander à la communauté');
  String get commSearchHint    => _t('Search community questions...',
                                     'Shakisha ibibazo by\'umuryango...',
                                     'Rechercher des questions...');
  String get commRelatedCrop   => _t('Related crop',          'Imbuto ishamikiyeho','Culture concernée');
  String get commQuestionLabel => _t('Question (English)',    'Ikibazo (Icyongereza)','Question (Anglais)');
  String get commQuestionKinLabel => _t('Kinyarwanda (Optional)', 'Kinyarwanda (Ntabwigenge)', 'Kinyarwanda (Facultatif)');

  // ── Profile Screen ────────────────────────────────────────────────────
  String get profileTitle       => _t('Profile · Umwirondoro', 'Umwirondoro',   'Profil');
  String get profileLearning    => _t('Learning Progress · Iterambere',
                                      "Iterambere mu Kwiga",
                                      "Progrès d'apprentissage");
  String get profileMyCrops     => _t('My Crops · Imbuto Zanjye','Imbuto Zanjye','Mes cultures');
  String get profileLanguage    => _t('Language · Ururimi',  'Ururimi',        'Langue');
  String get profileSettings    => _t('Settings · Igenamigambi','Igenamigambi', 'Paramètres');
  String get profileAbout       => _t('About AgriSense',     'Ibyerekeye AgriSense','À propos');
  String get profileNotif       => _t('Notifications · Imenyesha','Imenyesha',  'Notifications');
  String get profileDownload    => _t('Download for offline · Bika','Bika',     'Télécharger hors ligne');
  String get profileLocation    => _t('Location · Akarere',  'Akarere',        'Emplacement');
  String get profileCloudSync   => _t('Cloud sync · Backup', 'Backup',         'Sync cloud');
  String get profileSynced      => _t('✓ Profile synced to cloud','✓ Umwirondoro wabitswe','✓ Profil synchronisé');
  String get profileSignIn      => _t('Sign in to enable cloud sync','Injira kugira ngo ubike mu ruganda','Se connecter pour activer la sync');
  String get profileSignOut     => _t('Sign Out',            'Sohoka',         'Se déconnecter');
  String get profileEditName    => _t('Your Name · Amazina', 'Amazina yawe',   'Votre nom');
  String get profileSave        => _t('Save · Bika',         'Bika',           'Enregistrer');
  String get profileChangeDistrict => _t('Change District · Hindura Akarere',
                                         'Hindura Akarere',
                                         'Changer de district');
  String of(int count, String singular, String plural) =>
      count == 1 ? '$count $singular' : '$count $plural';
  String get lessonsOf => isRw ? 'mu masomo' : isFr ? 'sur les leçons' : 'of lessons';

  // ── Onboarding ────────────────────────────────────────────────────────
  String get onboardGetStarted  => _t('Get Started · TANGIRA','TANGIRA',       'Commencer');
  String get onboardSignIn      => _t('Already have an account? Sign in',
                                      'Usanzwe ufite konti? Injira',
                                      'Vous avez déjà un compte ? Se connecter');
  String get onboardChooseLang  => _t('Choose Language',     'Hitamo Ururimi',  'Choisir la langue');
  String get onboardIAm         => _t('I am a...',           'Ndi...',          'Je suis...');
  String get onboardYourDistrict=> _t('Your District',       'Akarere kawe',    'Votre district');
  String get onboardVerifyNum   => _t('Verify your number',  'Emeza inomero yawe','Vérifiez votre numéro');
  String get onboardSendCode    => _t('Send Verification Code','Ohereza Kode',  'Envoyer le code');
  String get onboardVerifyBtn   => _t('Verify & Enter AgriSense ✓',
                                      'Emeza Winjire AgriSense ✓',
                                      'Vérifier et entrer ✓');
  String get onboardContinue    => _t('Continue',            'Komeza',          'Continuer');
  String get onboardSearchDist  => _t('Search District · Shaka Akarere',
                                      'Shaka Akarere',
                                      'Rechercher un district');

  // ── Lesson Detail ─────────────────────────────────────────────────────
  String get lessonAbout      => _t('About this lesson', 'Ibyerekeye isomo', 'À propos de la leçon');
  String get lessonTakeaways  => _t('Key Takeaways · Ibikubiye', 'Ibikubiye', 'Points clés');
  String get lessonFeelsLike  => _t('Feels like', 'Bisa na', 'Ressent comme');
  String get lessonCompleted  => _t('✓ Lesson completed', '✓ Isomo ryarangiye', '✓ Leçon terminée');
  String get lessonProgress   => _t('Progress', 'Iterambere', 'Progrès');
  String get lessonAudioTitle => _t('Audio Lesson', 'Isomo ry\'Amajwi', 'Leçon audio');
  String get lessonTapListen  => _t('Tap to listen', 'Kanda wumve', 'Appuyez pour écouter');
  String get lessonPlaying    => _t('Playing...', 'Irimo gukinwa...', 'En cours...');
  String get lessonOffline    => _t('Offline', 'Bitswe', 'Hors ligne');
  String get lessonMinutes    => _t('minutes', 'iminota', 'minutes');
  String get lessonKeyword    => _t('Beginner', 'Intangiriro', 'Débutant');
  String get lessonIntermed   => _t('Intermediate', 'Hagati', 'Intermédiaire');
  String get lessonAdvanced   => _t('Advanced', 'Inzobere', 'Avancé');
  String get lessonAllLevels  => _t('All Levels', 'Amang\'anjye yose', 'Tous niveaux');
  String get lessonAudioFmt   => _t('Audio', 'Amajwi', 'Audio');
  String get lessonVideoFmt   => _t('Video', 'Videwo', 'Vidéo');
  String get lessonTextFmt    => _t('Text', 'Inyandiko', 'Texte');

  // ── Weather extra labels ───────────────────────────────────────────────
  String get weatherFeelsLike => _t('Feels like', 'Bisa na', 'Ressent comme');
  String get weatherHumidLabel => _t('Humidity', 'Ubuhehere', 'Humidité');
  String get weatherRainLabel  => _t('Rain', 'Imvura', 'Pluie');
  String get weatherWindLabel  => _t('Wind', 'Umuyaga', 'Vent');
  String get weatherUvLabel    => _t('UV', 'UV', 'UV');
  String get weatherChangeBtn  => _t('Change', 'Hindura', 'Changer');

  // ── Home tip / status labels ───────────────────────────────────────────
  String get homeTipTitle      => _t('Tip of the Day', "Inama y'uyu munsi", 'Conseil du jour');

  // ── Farmer types ──────────────────────────────────────────────────────
  String get farmerTypeFarmer    => _t('Farmer · Umuhinzi',        'Umuhinzi',        'Agriculteur');
  String get farmerTypeLandowner => _t("Landowner · Nyir'ubutaka", "Nyir'ubutaka",    'Propriétaire foncier');
  String get farmerTypeTrader    => _t('Trader · Umucuruzi',       'Umucuruzi',       'Commerçant');

  // ── Profile stats ─────────────────────────────────────────────────────
  String get statsCompleted   => _t('Completed',    'Byarangiye',   'Terminé');
  String get statsInProgress  => _t('In Progress',  'Birashoboka',  'En cours');
  String get statsCrops       => _t('Crops Tracked','Imbuto Zikurikiriwe', 'Cultures suivies');
  String get statsLessons     => _t('of lessons completed', 'mu masomo yize', 'leçons terminées');

  // ── Community post labels ─────────────────────────────────────────────
  String get commQuestion     => _t('Question',     'Ikibazo',      'Question');
  String get commReplies      => _t('replies',      'ibisubizo',    'réponses');
  String get commJustNow      => _t('Just now',     'Ubu nyine',    'À l\'instant');

  // ── Onboarding ────────────────────────────────────────────────────────
  String get onboardSmartFarm => _t('Smart Farming\nfor Every Farmer',
                                    'Ubuhinzi Bwa Gihanga\nku Muhinzi Wese',
                                    'Agriculture Intelligente\npour Chaque Agriculteur');
  String get onboardTagline   => _t('Smart Farming for Rwanda', 'Ubuhinzi Bwa Gihanga mu Rwanda', 'Agriculture Intelligente au Rwanda');
  String get onboardLang      => _t('Choose Language',  'Hitamo Ururimi',   'Choisir la langue');
  String get onboardWhoAreYou => _t('I am a...',        'Ndi...',           'Je suis...');
  String get onboardDistrict  => _t('Your District',    'Akarere kawe',     'Votre district');
  String get onboardVerify    => _t('Verify your number','Emeza inomero yawe','Vérifiez votre numéro');
  String get onboardResend    => _t("Didn't receive OTP? Resend",
                                    "Ntabwo wahawe kode? Ohereza nshya",
                                    "Pas reçu? Renvoyer");
  String get onboardCodeSent  => _t('Code sent!',       'Kode yoherejwe!',  'Code envoyé!');
  String get onboardCouldNot  => _t('Could not send code','Ntashobotse kohereza kode','Impossible d\'envoyer');
  String get onboardEnter6    => _t('Enter 6-Digit Code · Injiza Kode',
                                    'Injiza imibare 6 ya Kode',
                                    'Entrez le code à 6 chiffres');
  String get onboardYourCrops => _t('Your Crops',       'Imbuto zawe',      'Vos cultures');
  String get onboardSelectAll => _t('Select all that apply','Hitamo ibikurikira','Sélectionnez tout ce qui s\'applique');
  String get onboardAlmostThere => _t('Almost there!',  'Hafi ya kugera!',  'Presque là!');
  String get onboardPhoneLabel  => _t('Phone Number · Nimero ya Telefoni',
                                      'Nimero ya Telefoni',
                                      'Numéro de téléphone');
  String get onboardSending     => _t('Sending...',     'Gutumya...',       'Envoi...');
  String get onboardVerifying   => _t('Verifying...',   'Kwemeza...',       'Vérification...');

  // ── General ───────────────────────────────────────────────────────────
  String get genRetry       => _t('Retry',           'Ongera ugerageze',  'Réessayer');
  String get genCancel      => _t('Cancel',          'Reka',              'Annuler');
  String get genSave        => _t('Save',            'Bika',              'Enregistrer');
  String get genClose       => _t('Close',           'Funga',             'Fermer');
  String get genYes         => _t('Yes',             'Yego',              'Oui');
  String get genNo          => _t('No',              'Oya',               'Non');
  String get genLoading     => _t('Loading...',      'Gutegereza...',     'Chargement...');
  String get genNoData      => _t('No data available','Nta makuru aboneka','Aucune donnée disponible');
  String get genShare       => _t('Share',           'Sangira',           'Partager');
}
