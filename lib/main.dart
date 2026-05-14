import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ShinsengumiQuiz(),
    ));

class ShinsengumiQuiz extends StatefulWidget {
  @override
  _ShinsengumiQuizState createState() => _ShinsengumiQuizState();
}

class _ShinsengumiQuizState extends State<ShinsengumiQuiz> {
  bool _isStarted = false;
  String _selectedLevel = '入門'; 
  int _index = 0;
  int _score = 0;
  bool _isExplaning = false;
  bool _showOverlay = false;
  bool _lastCorrect = false;
  int? _userAnswerIndex;

  // ★追加：シャッフルされた今回のクイズリストを保持する変数
  List<Map<String, dynamic>> _shuffledQuizData = [];

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  List<String> _history = [];

// --- レベル別・称号計算ロジック（変更なし） ---
String _getRankText(double rate) {
  if (_selectedLevel == '入門') {
    if (rate == 1.0) return '一人前の平隊士';
    if (rate >= 0.7) return '見習い隊士';
    return '入隊志願者';
  } else if (_selectedLevel == '基礎') {
    if (rate == 1.0) return '精鋭隊士';
    if (rate >= 0.7) return '伍長クラス';
    return '平隊士';
  } else if (_selectedLevel == '中堅') {
    if (rate == 1.0) return '組長（斎藤・永倉 級）';
    if (rate >= 0.7) return '副長助勤';
    return '精鋭隊士';
  } else { // 極み
    if (rate == 1.0) return '局長（近藤・土方 級）';
    if (rate >= 0.8) return '新選組 参謀';
    if (rate >= 0.6) return '組長クラス';
    return '歴戦の隊士';
  }
}

// クイズデータ（各レベル30問に増強）
final Map<String, List<Map<String, dynamic>>> _quizData = {
  '入門': [
    {'q': '新選組の旗印に書かれている一文字は？', 'c': ['忠', '義', '誠', '勇'], 'a': 2, 'ex': '「誠」は武士のまごころを表します。'},
    {'q': '「鬼の副長」と呼ばれた人物は？', 'c': ['近藤勇', '土方歳三', '山南敬助', '斎藤一'], 'a': 1, 'ex': '土方歳三は規律を重んじ組織を統制しました。'},
    {'q': '羽織の特徴的な模様の名前は？', 'c': ['桜紋', 'だんだら模様', '亀甲紋', '菱形'], 'a': 1, 'ex': '赤穂浪士にあやかったデザインです。'},
    {'q': '一番隊組長を務めた天才剣士は？', 'c': ['沖田総司', '永倉新八', '斎藤一', '藤堂平助'], 'a': 0, 'ex': '若くして剣技に秀でていました。'},
    {'q': '新選組が活動していた主な都市は？', 'c': ['江戸', '大坂', '京都', '会津'], 'a': 2, 'ex': '京の治安維持が主な任務でした。'},
    {'q': '新選組の局長は誰？', 'c': ['土方歳三', '近藤勇', '芹沢鴨', '伊東甲子太郎'], 'a': 1, 'ex': '天然理心流の四代目宗家です。'},
    {'q': '隊士が守るべき厳しい掟を何と呼ぶ？', 'c': ['軍中法度', '局中法度', '士道心得', '武士道'], 'a': 1, 'ex': '背けば切腹という厳しいものでした。'},
    {'q': '新選組の象徴的な武器といえば？', 'c': ['槍', '鉄砲', '日本刀', '手裏剣'], 'a': 2, 'ex': '剣客集団として恐れられました。'},
    {'q': '隊士たちが集団で住んでいた場所を何と呼ぶ？', 'c': ['宿舎', '本陣', '屯所', '道場'], 'a': 2, 'ex': '壬生の八木邸などが有名です。'},
    {'q': '土方歳三が戦死した場所は？', 'c': ['京都', '会津', '箱館', '江戸'], 'a': 2, 'ex': '五稜郭の戦いで最期を迎えました。'},
    {'q': '新選組の羽織の色として有名なのは？', 'c': ['漆黒', '浅葱色', '黄金色', '真紅'], 'a': 1, 'ex': '薄い青色の「浅葱（あさぎ）色」が有名です。'},
    {'q': '近藤勇や土方歳三の出身地はどこ？', 'c': ['武蔵国（多摩）', '薩摩国', '長州国', '土佐国'], 'a': 0, 'ex': '現在の東京都多摩地域にあたります。'},
    {'q': '新選組の敵として有名な、長州藩の組織は？', 'c': ['奇兵隊', '白虎隊', '赤報隊', '彰義隊'], 'a': 0, 'ex': '高杉晋作が結成した諸隊の一つです。'},
    {'q': '近藤勇が大切にしていた流派の名前は？', 'c': ['北辰一刀流', '天然理心流', '鏡新明智流', '心形刀流'], 'a': 1, 'ex': '多摩で栄えた実戦重視の剣術です。'},
    {'q': '「誠」の旗の下に集まった隊士の最大人数は約何人？', 'c': ['50人', '200人以上', '1000人', '5000人'], 'a': 1, 'ex': '最盛期には200人を超える組織でした。'},
    {'q': '新選組を支援した会津藩主の名前は？', 'c': ['徳川慶喜', '松平容保', '島津斉彬', '伊達宗城'], 'a': 1, 'ex': '京都守護職として新選組を預かりました。'},
    {'q': '土方歳三が和装から洋装に変えたのはいつ頃？', 'c': ['結成当時', '池田屋事件後', '鳥羽・伏見の戦い後', '死後'], 'a': 2, 'ex': '戊辰戦争中、軍制の近代化に合わせて洋装になりました。'},
    {'q': '新選組の内部での連絡係や偵察を担った役職は？', 'c': ['組長', '監察', '伍長', '軍師'], 'a': 1, 'ex': '山崎丞などが監察として活躍しました。'},
    {'q': '新選組が最初に屯所を置いた村の名前は？', 'c': ['祇園村', '壬生村', '伏見村', '嵯峨村'], 'a': 1, 'ex': 'そのため「壬生浪士（みぶろ）」と呼ばれました。'},
    {'q': '近藤勇の最後を共にしたとされる愛刀は？', 'c': ['和泉守兼定', '虎徹', '加州清光', '堀川国広'], 'a': 1, 'ex': '長曽祢虎徹を愛用していた逸話が有名です。'},
    {'q': '土方歳三が箱館で組織した役職は？', 'c': ['総裁', '陸軍奉行並', '海軍総裁', '会計奉行'], 'a': 1, 'ex': '蝦夷共和国の陸軍奉行並に就任しました。'},
    {'q': '沖田総司が病に倒れた原因とされる病気は？', 'c': ['コレラ', '結核', 'インフルエンザ', '胃がん'], 'a': 1, 'ex': '当時は不治の病とされた肺結核でした。'},
    {'q': '新選組の副長は何人いた？', 'c': ['1人', '2人', '10人', '決まっていない'], 'a': 0, 'ex': '初期を除き、基本的には土方歳三の1人制でした。'},
    {'q': '「局中法度」で最も重い罪とされたのは？', 'c': ['遅刻', '無断外出', '士道に背くまじきこと', '喧嘩'], 'a': 2, 'ex': 'この一項目であらゆる違反を処罰できました。'},
    {'q': '新選組の給料を支払っていたのはどこ？', 'c': ['会津藩', '朝廷', '京都市民からの寄付', '自分たちの持ち出し'], 'a': 0, 'ex': '会津藩から運営費や給与が出ていました。'},
    {'q': '新選組の隊士募集はどこで行われた？', 'c': ['京都のみ', '江戸や多摩', '海外', '九州'], 'a': 1, 'ex': '江戸や多摩へ戻って大規模な募集を行いました。'},
    {'q': '斎藤一は何刀流と言われている？', 'c': ['右利き', '左利き', '二刀流', '槍術'], 'a': 1, 'ex': '諸説ありますが、左利きの説が非常に有名です。'},
    {'q': '「新選組」という名前を授けたのは誰？', 'c': ['近藤勇', '松平容保', '明治天皇', '徳川慶喜'], 'a': 1, 'ex': '会津藩主・松平容保から授かったとされます。'},
    {'q': '池田屋事件の功績で幕府から贈られたものは？', 'c': ['金一封', '城', '軍艦', '領地'], 'a': 0, 'ex': '莫大な賞金（金一封）が下賜されました。'},
    {'q': '新選組のドラマや映画で有名なテーマ曲といえば？', 'c': ['新選組！メインテーマ', '情熱大陸', 'ルパン三世', '和楽器バンド'], 'a': 0, 'ex': '大河ドラマ等の音楽は作品の象徴です。'},
  ],
  '基礎': [
    {'q': '池田屋事件が起きたのは西暦何年？', 'c': ['1860年', '1864年', '1867年', '1868年'], 'a': 1, 'ex': 'この事件で新選組の名が全国に轟きました。'},
    {'q': '二番隊組長で、後に「新選組顛末記」を残したのは？', 'c': ['永倉新八', '原田左之助', '斎藤一', '島田魁'], 'a': 0, 'ex': '生き残った隊士が貴重な記録を残しました。'},
    {'q': '十番隊組長で、槍の名手だったのは？', 'c': ['谷三十郎', '原田左之助', '井上源三郎', '松原忠司'], 'a': 1, 'ex': '原田左之助は腹を切っても死ななかった伝説があります。'},
    {'q': '新選組の前身となった組織の名前は？', 'c': ['彰義隊', '浪士組', '白虎隊', '海援隊'], 'a': 1, 'ex': '清河八郎の呼びかけで集まりました。'},
    {'q': '沖田総司が愛用したとされる刀の銘は？', 'c': ['和泉守兼定', '加州清光', '堀川国広', '陸奥守吉行'], 'a': 1, 'ex': '加州清光。池田屋事件の際に帽子が折れたと言われます。'},
    {'q': '三番隊組長・斎藤一が得意とした技は？', 'c': ['三段突き', '左片手一本突き', '燕返し', '無明剣'], 'a': 1, 'ex': '独特の突き技で恐れられました。'},
    {'q': '八木邸と共に最初の屯所となったのは何家？', 'c': ['前川邸', '角屋', '島原', '池田屋'], 'a': 0, 'ex': '壬生の八木邸と向かいの前川邸が拠点でした。'},
    {'q': '藤堂平助が新選組を離脱して入った組織は？', 'c': ['天誅組', '御陵衛士', '赤報隊', '遊撃隊'], 'a': 1, 'ex': '伊東甲子太郎と共に離脱しました。'},
    {'q': '新選組の医者（外科医）として知られる幕医は？', 'c': ['山崎丞', '松本良順', '島田魁', '河合耆三郎'], 'a': 1, 'ex': '幕府の奥医師で、新選組の健康を守りました。'},
    {'q': '井上源三郎が修めていた剣術の流派は？', 'c': ['北辰一刀流', '天然理心流', '神道念流', '一刀流'], 'a': 1, 'ex': '近藤や土方と同門の天然理心流です。'},
    {'q': '浪士組が京都へ到着した際、最初に宿泊した寺は？', 'c': ['金戒光明寺', '本能寺', '新徳寺', '清水寺'], 'a': 2, 'ex': '壬生の新徳寺で清河八郎が演説を行いました。'},
    {'q': '近藤勇の別称（諱）は何という？', 'c': ['義豊', '昌宜', '雅楽助', '勇五郎'], 'a': 1, 'ex': '諱は「昌宜（まさよし）」といいます。'},
    {'q': '土方歳三の実家が商売していた薬の名前は？', 'c': ['反魂丹', '石田散薬', '正露丸', '仁丹'], 'a': 1, 'ex': '骨折や打ち身に効くと言われる「石田散薬」です。'},
    {'q': '新選組の監察で「隠密」として池田屋事件でも活躍したのは？', 'c': ['山崎丞', '島田魁', '相馬主計', '吉村貫一郎'], 'a': 0, 'ex': '山崎丞は算術や医学にも心得がありました。'},
    {'q': '新選組が西本願寺に屯所を移した理由は？', 'c': ['広かったから', '嫌がらせ', '家賃が安かった', '防衛拠点'], 'a': 0, 'ex': '隊士が増え、壬生では手狭になったためです。'},
    {'q': '新選組の軍師的な役割も果たした「参謀」といえば？', 'c': ['武田観柳斎', '伊東甲子太郎', '山南敬助', '清河八郎'], 'a': 1, 'ex': '伊東甲子太郎が参謀として迎えられました。'},
    {'q': '山南敬助が切腹した理由とされるのは？', 'c': ['殺人', '借金', '脱走', '意見の相違'], 'a': 2, 'ex': '「局中法度」の脱走の罪に問われました。'},
    {'q': '鳥羽・伏見の戦いで新選組が戦った相手は？', 'c': ['新政府軍', '会津軍', '幕府軍', 'アメリカ軍'], 'a': 0, 'ex': '薩摩・長州を中心とする新政府軍と戦いました。'},
    {'q': '新選組の伍長の役割は？', 'c': ['情報収集', '5人の隊士をまとめる', '給料計算', '料理番'], 'a': 1, 'ex': '最小単位のチームリーダーです。'},
    {'q': '沖田総司の「三段突き」はどこの部位を突く？', 'c': ['喉・右肩・左肩', '胸・腹・足', '面・小手・胴', '全部喉'], 'a': 0, 'ex': '一瞬で三つの箇所を突く神速の技とされます。'},
    {'q': '新選組の中で「鬼の副長」の右腕だったのは？', 'c': ['斎藤一', '島田魁', '松原忠司', '安藤早太郎'], 'a': 1, 'ex': '島田魁は巨漢で土方を支え続けました。'},
    {'q': '近藤勇が多摩で開いていた道場の名前は？', 'c': ['試衛館', '練兵館', '玄武館', '士学館'], 'a': 0, 'ex': '江戸の市ヶ谷にあった道場が試衛館です。'},
    {'q': '新選組の旗印の裏に書かれている文字は？', 'c': ['誠', '義', '会津', 'なし'], 'a': 3, 'ex': '基本的には表面のみに「誠」と書かれています。'},
    {'q': '戊辰戦争中、新選組が最後に戦った地はどこ？', 'c': ['会津', '宇都宮', '箱館', '仙台'], 'a': 2, 'ex': '北海道の箱館（函館）が終焉の地となりました。'},
    {'q': '新選組の中で料理が上手だったとされる組長は？', 'c': ['沖田総司', '井上源三郎', '斎藤一', '原田左之助'], 'a': 1, 'ex': '井上源三郎は温厚で隊士たちに慕われていました。'},
    {'q': '土方歳三が箱館で使用した馬の名前は？', 'c': ['大嵐', '一文字', '不知火', 'なし'], 'a': 3, 'ex': '特定の愛馬の名前は記録に残っていません。'},
    {'q': '近藤勇が「虎徹」を手に入れた際の値段は？', 'c': ['10両', '50両', '100両', '貰い物'], 'a': 1, 'ex': '50両という大金で購入したと言われています（諸説あり）。'},
    {'q': '新選組を脱退して生き残り、後に警官になったのは？', 'c': ['斎藤一', '藤堂平助', '山南敬助', '芹沢鴨'], 'a': 0, 'ex': '斎藤一は藤田五郎と改名し、警視庁に勤務しました。'},
    {'q': '新選組の中で「相撲」が得意だった隊士は？', 'c': ['島田魁', '永倉新八', '山崎丞', '近藤勇'], 'a': 0, 'ex': '島田魁は巨漢で、力自慢として知られました。'},
    {'q': '新選組が公式に認められた「御預」の期間は約何年？', 'c': ['1年', '5年', '10年', '20年'], 'a': 1, 'ex': '1863年から1868年の約5年間です。'},
  ],
  '中堅': [
    {'q': '山南敬助が切腹した際、介錯を務めたのは？', 'c': ['近藤勇', '土方歳三', '沖田総司', '斎藤一'], 'a': 2, 'ex': '親友だった沖田が涙ながらに務めました。'},
    {'q': '新選組が西本願寺から移転した、京都最後の屯所は？', 'c': ['不動堂村', '壬生', '二条城', '伏見'], 'a': 0, 'ex': '設備が非常に豪華な屯所だったと言われています。'},
    {'q': '油小路の変で暗殺された、元参謀の人物は？', 'c': ['芹沢鴨', '伊東甲子太郎', '清河八郎', '武市半平太'], 'a': 1, 'ex': '新選組から分離した御陵衛士の盟主でした。'},
    {'q': '土方歳三の愛刀「和泉守兼定」は何代目？', 'c': ['2代目', '11代目', '12代目', '15代目'], 'a': 1, 'ex': '11代目兼定とされています。'},
    {'q': '「諸士調役兼監察」として情報収集に当たった人物は？', 'c': ['山崎丞', '武田観柳斎', '松原忠司', '尾形俊太郎'], 'a': 0, 'ex': '山崎は町人姿で情報を探るプロでした。'},
    {'q': '池田屋事件の際、土方隊が最初に向かった先は？', 'c': ['池田屋', '四国屋', '三条河原', '角屋'], 'a': 1, 'ex': '当初は四国屋が怪しいと睨んで別行動していました。'},
    {'q': '近藤勇が処刑（斬首）された場所はどこ？', 'c': ['六条河原', '板橋', '小塚原', '鴨川'], 'a': 1, 'ex': '下総流山で投降した後、板橋で処刑されました。'},
    {'q': '永倉新八が明治以降、松前藩で名乗った名前は？', 'c': ['杉村治左衛門', '杉村義衛', '長倉一平', '永倉新八'], 'a': 1, 'ex': '婿養子となり、杉村義衛と名乗りました。'},
    {'q': '新選組の中で「文学師範」を務めていた人物は？', 'c': ['伊東甲子太郎', '武田観柳斎', '山南敬助', '松原忠司'], 'a': 1, 'ex': '武田は軍事学も教えていました。'},
    {'q': '伏見奉行所から撤退する際、決死の殿を務めたのは？', 'c': ['土方歳三', '永倉新八', '斎藤一', '原田左之助'], 'a': 1, 'ex': '永倉率いる決死隊が旧幕府軍を支えました。'},
    {'q': '近藤勇の本姓（名字）は何という？', 'c': ['島崎', '宮川', '石田', '内藤'], 'a': 1, 'ex': '武州多摩の農民・宮川家の三男でした。'},
    {'q': '新選組の内紛「芹沢鴨暗殺」に関わっていないのは？', 'c': ['土方歳三', '沖田総司', '藤堂平助', '永倉新八'], 'a': 3, 'ex': '実行犯は土方、沖田、山南、原田らと言われています。'},
    {'q': '土方歳三が「豊玉」の号で残したものは何？', 'c': ['日記', '俳句集', '剣術書', '算術書'], 'a': 1, 'ex': '「豊玉発句集」という句集を残しています。'},
    {'q': '新選組の監察・吉村貫一郎の出身藩はどこ？', 'c': ['南部藩', '米沢藩', '庄内藩', '津軽藩'], 'a': 0, 'ex': '「義士」として名高い吉村は南部藩の出身です。'},
    {'q': '近藤勇が甲陽鎮撫隊として出陣した際の変名は？', 'c': ['内藤隼人', '大久保大和', '広沢金次郎', '山口一'], 'a': 1, 'ex': '大久保大和と名乗り、幕府の若年寄を称しました。'},
    {'q': '池田屋事件の際、近藤隊は何人で池田屋に突入した？', 'c': ['4人', '10人', '20人', '30人'], 'a': 0, 'ex': '近藤、沖田、永倉、藤堂のわずか4人で突入しました。'},
    {'q': '「魁（さきがけ）先生」というあだ名で呼ばれた隊士は？', 'c': ['島田魁', '藤堂平助', '山南敬助', '斎藤一'], 'a': 1, 'ex': '常に先陣を切って戦ったため「魁先生」と呼ばれました。'},
    {'q': '新選組の制服（だんだら羽織）が廃止されたのはいつ頃？', 'c': ['池田屋事件前', '池田屋事件後', '西本願寺移転後', '鳥羽伏見戦後'], 'a': 1, 'ex': '池田屋事件の1年後くらいには着られなくなったと言われます。'},
    {'q': '斎藤一が新選組時代に使っていた偽名は？', 'c': ['山口一', '藤田五郎', '一ノ進', '関一'], 'a': 0, 'ex': '初期は山口一（やまぐちはじめ）を名乗っていました。'},
    {'q': '油小路の変で新選組が待ち伏せに使用した場所は？', 'c': ['本行寺', '不動堂村屯所', '角屋', '壬生寺'], 'a': 0, 'ex': '本行寺の付近で御陵衛士を襲撃しました。'},
    {'q': '新選組の中で「フランス式軍事訓練」を導入しようとしたのは？', 'c': ['近藤勇', '土方歳三', '武田観柳斎', '山南敬助'], 'a': 1, 'ex': '土方は旧来の剣術から銃火器主体の近代戦へ転換させました。'},
    {'q': '原田左之助が使っていた槍の種類は？', 'c': ['片鎌槍', '十文字槍', '素槍', '大身槍'], 'a': 2, 'ex': '一間半（約2.7m）の素槍を得意としました。'},
    {'q': '近藤勇が処刑される直前、詠んだとされる漢詩の題名は？', 'c': ['孤軍', '義烈', '絶命詩', 'なし'], 'a': 2, 'ex': '「孤軍奮闘、包囲に陥り…」という絶命詩を残しました。'},
    {'q': '新選組が資金調達のために京都の豪商を脅した事件は？', 'c': ['ぜんざい屋事件', '岩城升屋事件', '蔵屋敷事件', 'なし'], 'a': 1, 'ex': '不逞浪士から商人を守る名目で強引な集金もありました。'},
    {'q': '土方歳三が最期に戦死した際、率いていた部隊は？', 'c': ['陸軍', '新選組', '額兵隊', '伝習隊'], 'a': 1, 'ex': '箱館で生き残った新選組隊士を率いていました。'},
    {'q': '新選組の中で「副長助勤」とはどのような役職？', 'c': ['掃除係', '組長クラス', '会計係', '門番'], 'a': 1, 'ex': '各組の組長などが就く、幹部役職です。'},
    {'q': '新選組の伍長・島田魁が記した日記の名前は？', 'c': ['新選組始末記', '島田魁日記', '島田魁手帳', '戊辰日記'], 'a': 1, 'ex': '「島田魁日記」は新選組研究の貴重な資料です。'},
    {'q': '近藤勇が松平容保に謁見した際に頂いたものは？', 'c': ['刀', '扇子', '陣羽織', '鉢金'], 'a': 2, 'ex': '緋羅紗（ひらしゃ）の陣羽織を頂いたとされます。'},
    {'q': '山南敬助が切腹した屯所の部屋の名前は？', 'c': ['仏間', '奥の間', '前川邸のサンルーム', 'なし'], 'a': 0, 'ex': '前川邸の仏間で自刃しました。'},
    {'q': '新選組が池田屋事件の報奨金で一番多く貰ったのは？', 'c': ['近藤勇', '土方歳三', '沖田総司', '全員同じ'], 'a': 0, 'ex': '近藤勇が最も多く（30両）受け取っています。'},
  ],
  '極み': [
    {'q': '初代筆頭局長・芹沢鴨が暗殺された日付はいつ？', 'c': ['文久3年9月16日', '文久3年12月20日', '元治元年6月5日', '慶応3年11月18日'], 'a': 0, 'ex': '土方・沖田らが深夜に寝込みを襲いました。'},
    {'q': '近藤勇が愛用した「虎徹」の本来の作者名は？', 'c': ['長曽祢興里', '和泉守兼定', '加州清光', '不明'], 'a': 0, 'ex': '長曽祢興里（入道虎徹）が作者の名前です。'},
    {'q': '斎藤一が明治以降に警察官として名乗った名前は？', 'c': ['藤田五郎', '杉村義衛', '山口一', '広沢金次郎'], 'a': 0, 'ex': '藤田五郎として警視庁に勤めました。'},
    {'q': '箱館戦争で土方と共に戦った、伝習隊の隊長は？', 'c': ['榎本武揚', '大鳥圭介', '松平容保', '河井継之助'], 'a': 1, 'ex': '大鳥圭介は旧幕府軍の陸軍奉行でした。'},
    {'q': '伊東甲子太郎が暗殺された場所の正しい地名は？', 'c': ['油小路', '七条', '木屋町', '河原町'], 'a': 0, 'ex': '七条油小路付近で新選組の待ち伏せを受けました。'},
    {'q': '新選組の旗印の「誠」を誰が書いたかは…？', 'c': ['近藤勇', '松平容保', '特定されていない', '伊東甲子太郎'], 'a': 2, 'ex': '実は誰が筆を執ったか確かな記録はありません。'},
    {'q': '新選組が正式に「会津藩御預」となったのはいつ？', 'c': ['1862年', '1863年', '1864年', '1865年'], 'a': 1, 'ex': '文久3年（1863年）に認可されました。'},
    {'q': '土方歳三が宇都宮城の戦いで負傷した場所は？', 'c': ['足', '右腕', '腹部', '頭部'], 'a': 0, 'ex': '足を撃たれ、しばらく治療に専念しました。'},
    {'q': '新選組が江戸へ戻る際に乗船した軍艦はどれ？', 'c': ['咸臨丸', '富士山丸', '富士川丸', '順動丸'], 'a': 1, 'ex': '富士山丸で海路から江戸へ逃れました。'},
    {'q': '近藤勇の養父で、天然理心流三代目宗家は？', 'c': ['近藤周斎', '近藤内蔵助', '近藤助五郎', '近藤三助'], 'a': 0, 'ex': '周斎が近藤勇を養子として迎えました。'},
    {'q': '芹沢鴨が「神道無念流」のどこで免許皆伝を得た？', 'c': ['練兵館', '玄武館', '士学館', '戸賀崎道場'], 'a': 3, 'ex': '水戸の戸賀崎道場（百合之介）の門下でした。'},
    {'q': '近藤勇の長女の名前は？', 'c': ['たま', 'みつ', 'よね', 'さと'], 'a': 0, 'ex': '名は「たま」。土方の助言で従兄弟の勇五郎と結婚しました。'},
    {'q': '土方歳三の遺髪と写真を箱館から日野へ届けた人物は？', 'c': ['市村鉄之助', '中島登', '島田魁', '相馬主計'], 'a': 0, 'ex': '当時16歳の少年隊士、市村鉄之助が命懸けで届けました。'},
    {'q': '新選組最後の局長（第3代）に就任した人物は？', 'c': ['斎藤一', '土方歳三', '相馬主計', '島田魁'], 'a': 2, 'ex': '箱館で土方亡き後、相馬主計が局長を引き継ぎました。'},
    {'q': '「今弁慶」と呼ばれた巨漢隊士、島田魁の刀の重さは？', 'c': ['2kg', '4kg', '10kg', '不明'], 'a': 1, 'ex': '一貫三百匁（約4.9kg）の重い鉄棒や刀を振ったと言われます。'},
    {'q': '近藤勇が甲府城を接収しようとして失敗した戦いの名前は？', 'c': ['勝沼の戦い', '上野の戦い', '今井の戦い', '流山の戦い'], 'a': 0, 'ex': '甲州勝沼の戦いで板垣退助率いる新政府軍に敗れました。'},
    {'q': '土方歳三が宇都宮で足を負傷した際に治療した医師は？', 'c': ['松本良順', 'ボードウィン', '司馬凌海', 'なし'], 'a': 1, 'ex': '医学者のボードウィン（オランダ人）の診察を受けました。'},
    {'q': '斎藤一が会津戦争で新選組を離脱して残った場所は？', 'c': ['鶴ヶ城', '如来堂', '飯盛山', '日光'], 'a': 1, 'ex': '如来堂で包囲されるも、「会津を見捨てられない」と残りました。'},
    {'q': '沖田総司の戒名「賢光院仁誉明道居士」を与えた寺は？', 'c': ['専称寺', '光忠寺', '壬生寺', '本願寺'], 'a': 0, 'ex': '港区の専称寺に沖田の墓があります。'},
    {'q': '新選組の中で「算術」に長け、会計を担当した幹部は？', 'c': ['河合耆三郎', '武田観柳斎', '山崎丞', '安藤早太郎'], 'a': 0, 'ex': '勘定方として活躍しましたが、後に責任を取らされ切腹。'},
    {'q': '土方歳三の「和泉守兼定」の刃長は何寸何分？', 'c': ['2尺3寸1分', '2尺8寸', '2尺1寸', '3尺'], 'a': 0, 'ex': '約70.3cm（2尺3寸1分）あったと言われています。'},
    {'q': '「新選組」の名が初めて公文書に現れた日付は？', 'c': ['文久3年8月18日', '文久3年3月10日', '元治元年6月5日', '慶応3年10月'], 'a': 0, 'ex': '八月十八日の政変の際、褒賞を受けた際の名が初出です。'},
    {'q': '浪士組の中で新選組に残らず、江戸へ戻った清河派の数は？', 'c': ['約10人', '約50人', '約200人', '全員'], 'a': 2, 'ex': '清河八郎と共に200人以上が江戸へ引き返しました。'},
    {'q': '近藤勇が「虎徹」を鑑定させた人物の名前は？', 'c': ['細工師・長右衛門', '研師・源兵衛', '土方歳三', 'なし'], 'a': 1, 'ex': '偽物と知りつつ、本物だと信じて使い続けました（諸説あり）。'},
    {'q': '永倉新八が小樽で看護師たちに剣術を教えた際の流派名は？', 'c': ['天然理心流', '神道無念流', '一刀流', '心形刀流'], 'a': 1, 'ex': '永倉はもともと神道無念流の免許皆伝です。'},
    {'q': '箱館政府の閣僚名簿で、土方歳三の「得票数」は何位？', 'c': ['1位', '2位', '4位', '最下位'], 'a': 2, 'ex': '榎本武揚らに次ぎ、陸軍奉行並として4位の得票でした。'},
    {'q': '近藤勇が流山で投降した際、官軍に名乗った偽名の由来は？', 'c': ['近所の地名', '養父の名前', '土方の親戚', '適当'], 'a': 2, 'ex': '土方歳三の親戚筋の「大久保大和」を名乗りました。'},
    {'q': '新選組の中で「暗殺された」ことが確定している幹部は？', 'c': ['井上源三郎', '松原忠司', '武田観柳斎', '近藤勇'], 'a': 2, 'ex': '武田は鴨川の銭取橋付近で、斎藤一らに暗殺されました。'},
    {'q': '山南敬助の脱走を追いかけた隊士は？', 'c': ['土方歳三', '沖田総司', '斎藤一', '原田左之助'], 'a': 1, 'ex': '近藤の命令により、一番仲の良かった沖田が追いました。'},
    {'q': '土方歳三の生家「石田」の家紋は何？', 'c': ['三つ巴', '左三つ巴', '丸に右三つ巴', '丸に剣花菱'], 'a': 2, 'ex': '「丸に右三つ巴」が土方家の家紋です。'},
  ],
};
  @override
  void initState() {
    super.initState();
    _setupBGM();
    _loadHistory();
  }

  // ★追加：クイズ開始時にデータをシャッフルするメソッド
  void _startQuiz() {
    // 選択されたレベルのデータをコピー
    List<Map<String, dynamic>> rawList = List.from(_quizData[_selectedLevel]!);
    
    // 1. 問題自体の順序をランダムにする
    rawList.shuffle();

    // 2. 各問題の選択肢もランダムにする
    _shuffledQuizData = rawList.map((item) {
      // 選択肢をコピー
      List<String> choices = List<String>.from(item['c']);
      // 正解の文字列を先に保存しておく
      String correctAnswer = choices[item['a']];
      // 選択肢をシャッフル
      choices.shuffle();
      // シャッフル後のリストから正解のインデックスを再検索
      int newCorrectIndex = choices.indexOf(correctAnswer);

      return {
        'q': item['q'],
        'c': choices,
        'a': newCorrectIndex,
        'ex': item['ex'],
      };
    }).toList();

    _bgmPlayer.play(AssetSource('bgm.mp3'));
    setState(() {
      _index = 0;
      _score = 0;
      _isStarted = true;
    });
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _history = prefs.getStringList('quiz_history') ?? []; });
  }

  Future<void> _saveHistory(int score) async {
    final prefs = await SharedPreferences.getInstance();
    double rate = score / _shuffledQuizData.length;
    String rank = _getRankText(rate);
    String date = "${DateTime.now().month}/${DateTime.now().day} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    String record = "$date 【$_selectedLevel】 $score点 ($rank)";
    _history.insert(0, record);
    if (_history.length > 5) _history = _history.sublist(0, 5);
    await prefs.setStringList('quiz_history', _history);
  }

  void _setupBGM() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.1);
  }

  void _handleAnswer(int selected) {
    var currentQuiz = _shuffledQuizData[_index];
    bool isCorrect = (selected == currentQuiz['a']);
    if (isCorrect) _score++;
    _effectPlayer.play(AssetSource(isCorrect ? 'correct.mp3' : 'wrong.mp3'));

    setState(() {
      _userAnswerIndex = selected;
      _lastCorrect = isCorrect;
      _showOverlay = true;
      _isExplaning = true;
    });

    if (_index == _shuffledQuizData.length - 1) {
      _saveHistory(_score);
    }

    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

@override
  Widget build(BuildContext context) {
    // クイズが終了したかどうかの判定
    bool finished = _isStarted && _index >= _shuffledQuizData.length;

    return Scaffold(
      // ★ クイズ中（開始済みかつ未終了）だけホームボタン付きのAppBarを表示
      appBar: (_isStarted && !finished)
          ? AppBar(
              backgroundColor: const Color(0xFF00A3AF),
              elevation: 0,
              centerTitle: true,
              title: Text(
                '第 ${_index + 1} / ${_shuffledQuizData.length} 問',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () => _showExitConfirmation(context), // 確認ダイアログを呼ぶ
              ),
            )
          : null, // スタート画面と結果画面ではAppBarを出さない
      body: Stack(
        children: [
          Container(color: const Color(0xFF00A3AF)), // 背景色
          SafeArea(
            child: Center(
              child: _isStarted
                  ? (finished ? _buildResult() : _buildQuiz())
                  : _buildStartScreen(),
            ),
          ),
          if (_showOverlay) _buildResultOverlay(),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('中断しますか？'),
        content: const Text('ホームに戻ると、現在のスコアは消えてしまいます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('続ける'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isStarted = false;
                _index = 0;
                _score = 0;
              });
            },
            child: const Text('ホームに戻る', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStartScreen() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('新選組', style: TextStyle(fontSize: 24, color: Colors.white, letterSpacing: 8)),
          Text('出世検定', style: TextStyle(fontSize: 60, color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          Text('ー 修練のレベルを選べ ー', style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: ['入門', '基礎', '中堅', '極み'].map((level) {
              bool isSelected = _selectedLevel == level;
              return ChoiceChip(
                label: Text(level, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: Colors.black87,
                backgroundColor: Colors.white70,
                onSelected: (bool selected) { setState(() { _selectedLevel = level; }); },
              );
            }).toList(),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20)),
            onPressed: _startQuiz, // ★変更：シャッフル処理を呼ぶ
            child: Text('いざ、参る！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          if (_history.isNotEmpty) ...[
            SizedBox(height: 40),
            Text('ー 過去の戦績（直近5件）ー', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ..._history.map((h) => Padding(padding: EdgeInsets.only(top: 5), child: Text(h, style: TextStyle(color: Colors.white)))),
          ]
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    var quiz = _shuffledQuizData[_index];
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text('【$_selectedLevel】 第 ${_index + 1} / 10 問', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Card(elevation: 5, child: Padding(padding: EdgeInsets.all(25), child: Text(quiz['q'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
            SizedBox(height: 30),
            if (!_isExplaning)
              ...List.generate(4, (i) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                  child: Text(quiz['c'][i], style: TextStyle(fontSize: 18)), onPressed: () => _handleAnswer(i))),
              )),
            if (_isExplaning)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20), 
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10)), 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('あなたの回答: ${quiz['c'][_userAnswerIndex!]}', style: TextStyle(color: _lastCorrect ? Colors.greenAccent : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('正解: ${quiz['c'][quiz['a']]}', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Divider(color: Colors.white30),
                        Text(quiz['ex'], style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5)),
                      ],
                    )
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87),
                    child: Text('次へ進む'), onPressed: () => setState(() { _isExplaning = false; _index++; _userAnswerIndex = null; })),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    int total = _shuffledQuizData.length;
    double rate = _score / total;
    String rankName = _getRankText(rate);

    return Container(
      margin: EdgeInsets.all(24), padding: EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('【$_selectedLevel】 判定結果', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('$_score / $total 正解', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red)),
          Divider(height: 30),
          Text('称号', style: TextStyle(fontSize: 16, color: Colors.grey)),
          Text(rankName, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF00A3AF)), textAlign: TextAlign.center),
          SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white),
            child: Text('戻る'), onPressed: () => setState(() { _index = 0; _score = 0; _isExplaning = false; _isStarted = false; })),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    return Container(color: Colors.black.withOpacity(0.5), child: Center(child: Icon(_lastCorrect ? Icons.circle_outlined : Icons.close, size: 240, color: _lastCorrect ? Colors.cyanAccent : Colors.redAccent)));
  }
}