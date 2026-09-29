import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/database/quiz_dao.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';

class SeedData {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final dao = QuizDao(db);
    if (await dao.quizCount() > 0) return;
    for (final quiz in _packs) {
      await dao.upsertQuiz(quiz);
    }
  }

  static Quiz _q(String id, String title, String cat, List<Question> qs) => Quiz(
        id: id,
        title: title,
        category: cat,
        createdAt: DateTime(2024),
        questions: qs,
      );

  static Question _btn(String id, String qz, String q,
          List<String> correct, List<String> wrong,
          {String? fact}) =>
      Question(
        id: id,
        quizId: qz,
        slideType: SlideType.buttons,
        question: q,
        correctAnswers: correct,
        falseAnswers: wrong,
        funFact: fact,
      );

  static Future<void> ensureDemoMix(AppDatabase db) async {
    final dao = QuizDao(db);
    if (await dao.getQuizById('mix') != null) return;
    await dao.upsertQuiz(_mixQuiz);
  }

  static final Quiz _mixQuiz = _q('mix', '🎯 All Question Types Demo', 'Demo', [
    Question(
      id: 'mix1', quizId: 'mix',
      slideType: SlideType.buttons,
      question: 'Which planet is called the Red Planet?',
      correctAnswers: ['Mars'],
      falseAnswers: ['Venus', 'Jupiter', 'Saturn'],
      funFact: 'Mars appears red due to iron oxide (rust) on its surface.',
    ),
    Question(
      id: 'mix2', quizId: 'mix',
      slideType: SlideType.checkboxes,
      question: 'Which of these are mammals? (Select all that apply)',
      correctAnswers: ['Dog', 'Whale', 'Bat'],
      falseAnswers: ['Salmon', 'Eagle'],
    ),
    Question(
      id: 'mix3', quizId: 'mix',
      slideType: SlideType.infoSlide,
      question: '📚 Quick Fact!',
      funFact: 'Bats are the only mammals capable of sustained flight. They make up about 20% of all classified mammal species worldwide!',
    ),
    Question(
      id: 'mix4', quizId: 'mix',
      slideType: SlideType.reorder,
      question: 'Order these planets from closest to farthest from the Sun:',
      orderedItems: ['Mercury', 'Venus', 'Earth', 'Mars'],
    ),
    Question(
      id: 'mix5', quizId: 'mix',
      slideType: SlideType.range,
      question: 'What is the boiling point of water in °C?',
      correctValue: 100,
      minValue: 0,
      maxValue: 200,
      unit: '°C',
      funFact: 'Water boils at 100°C at sea level. At higher altitudes it boils at lower temperatures.',
    ),
    Question(
      id: 'mix6', quizId: 'mix',
      slideType: SlideType.typeAnswer,
      question: 'What is the capital city of Japan?',
      typeAnswer: 'Tokyo',
      funFact: 'Tokyo is the most populous metropolitan area in the world, with about 37 million people.',
    ),
    Question(
      id: 'mix7', quizId: 'mix',
      slideType: SlideType.buttons,
      question: 'Who invented the telephone?',
      correctAnswers: ['Alexander Graham Bell'],
      falseAnswers: ['Thomas Edison', 'Nikola Tesla', 'Albert Einstein'],
    ),
    Question(
      id: 'mix8', quizId: 'mix',
      slideType: SlideType.checkboxes,
      question: 'Which of these countries are in Europe? (Select all)',
      correctAnswers: ['France', 'Germany', 'Italy'],
      falseAnswers: ['Brazil', 'Japan'],
    ),
    Question(
      id: 'mix9', quizId: 'mix',
      slideType: SlideType.range,
      question: 'How many bones does the adult human body have?',
      correctValue: 206,
      minValue: 150,
      maxValue: 250,
      funFact: 'Babies have around 270–300 bones; many fuse together as we grow.',
    ),
    Question(
      id: 'mix10', quizId: 'mix',
      slideType: SlideType.typeAnswer,
      question: 'What is the chemical formula for water?',
      typeAnswer: 'H2O',
      funFact: 'H₂O: two hydrogen atoms bonded to one oxygen atom.',
    ),
  ]);

  static final List<Quiz> _packs = [
    // ── General Knowledge ──────────────────────────────────────────
    _q('gk', 'General Knowledge', 'General', [
      _btn('gk1','gk','What is the capital of France?',['Paris'],['London','Berlin','Madrid'],fact:'Paris has been France\'s capital since 987 AD.'),
      _btn('gk2','gk','Which planet is known as the Red Planet?',['Mars'],['Venus','Jupiter','Saturn'],fact:'Mars appears red due to iron oxide on its surface.'),
      _btn('gk3','gk','How many continents are there on Earth?',['7'],['5','6','8']),
      _btn('gk4','gk','What is the largest ocean?',['Pacific'],['Atlantic','Indian','Arctic']),
      _btn('gk5','gk','Who wrote Romeo and Juliet?',['Shakespeare'],['Dickens','Tolstoy','Austen']),
      _btn('gk6','gk','What is H2O commonly known as?',['Water'],['Hydrogen','Oxygen','Salt']),
      _btn('gk7','gk','How many sides does a hexagon have?',['6'],['5','7','8']),
      _btn('gk8','gk','Which country invented tea?',['China'],['India','Japan','England']),
      _btn('gk9','gk','What is the fastest land animal?',['Cheetah'],['Lion','Horse','Jaguar']),
      _btn('gk10','gk','Who painted the Mona Lisa?',['Leonardo da Vinci'],['Michelangelo','Raphael','Picasso']),
      _btn('gk11','gk','How many bones are in the adult human body?',['206'],['208','200','212']),
      _btn('gk12','gk','What is the chemical symbol for gold?',['Au'],['Go','Gd','Ag']),
      _btn('gk13','gk','Which gas do plants absorb from the atmosphere?',['Carbon Dioxide'],['Oxygen','Nitrogen','Hydrogen']),
      _btn('gk14','gk','What is the tallest mountain in the world?',['Mount Everest'],['K2','Kangchenjunga','Lhotse']),
      _btn('gk15','gk','How many days are in a leap year?',['366'],['365','367','368']),
      _btn('gk16','gk','What organ pumps blood around the body?',['Heart'],['Liver','Lungs','Kidney']),
      _btn('gk17','gk','Which country is the largest by area?',['Russia'],['Canada','USA','China']),
      _btn('gk18','gk','What is the square root of 144?',['12'],['11','13','14']),
      _btn('gk19','gk','Which language has the most native speakers?',['Mandarin Chinese'],['English','Spanish','Hindi']),
      _btn('gk20','gk','What is the hardest natural substance?',['Diamond'],['Quartz','Granite','Corundum']),
    ]),

    // ── Bollywood ──────────────────────────────────────────────────
    _q('bw', 'Bollywood Buzz', 'Bollywood', [
      _btn('bw1','bw','Who directed the movie "Dilwale Dulhania Le Jayenge"?',['Aditya Chopra'],['Karan Johar','Sanjay Leela Bhansali','Mani Ratnam']),
      _btn('bw2','bw','Which actor played the role of Munna Bhai?',['Sanjay Dutt'],['Salman Khan','Aamir Khan','Shah Rukh Khan']),
      _btn('bw3','bw','In which year was the film "Mughal-E-Azam" released?',['1960'],['1955','1962','1965']),
      _btn('bw4','bw','Who composed the music for "Sholay"?',['R.D. Burman'],['Lata Mangeshkar','S.D. Burman','Kalyanji Anandji']),
      _btn('bw5','bw','Which film won the Filmfare Award for Best Film in 2023?',['Gangubai Kathiawadi'],['The Kashmir Files','Brahmastra','RRR']),
      _btn('bw6','bw','Who is known as the "King of Bollywood"?',['Shah Rukh Khan'],['Amitabh Bachchan','Salman Khan','Aamir Khan']),
      _btn('bw7','bw','Which actress debuted in "Maine Pyar Kiya"?',['Bhagyashree'],['Madhuri Dixit','Sridevi','Juhi Chawla']),
      _btn('bw8','bw','Which Hindi film crossed ₹1000 crore worldwide first in 2023?',['Pathaan'],['Jawan','Dangal','Brahmastra']),
      _btn('bw9','bw','Who directed "Lagaan"?',['Ashutosh Gowariker'],['Aamir Khan','Rakeysh Omprakash Mehra','Farhan Akhtar']),
      _btn('bw10','bw','Which film features the song "Jai Ho"?',['Slumdog Millionaire'],['Lagaan','Swades','Rang De Basanti']),
      _btn('bw11','bw','Amitabh Bachchan\'s breakthrough film?',['Zanjeer'],['Sholay','Deewar','Don']),
      _btn('bw12','bw','Who plays Piku in the movie Piku?',['Deepika Padukone'],['Priyanka Chopra','Alia Bhatt','Kareena Kapoor']),
      _btn('bw13','bw','Which film has the song "Chaiyya Chaiyya"?',['Dil Se'],['DDLJ','Kuch Kuch Hota Hai','Mohabbatein']),
      _btn('bw14','bw','Who starred in "3 Idiots"?',['Aamir Khan'],['Ranbir Kapoor','Hrithik Roshan','Farhan Akhtar']),
      _btn('bw15','bw','Which studio produces the most Bollywood films?',['Yash Raj Films'],['Dharma Productions','T-Series','Eros Now']),
      _btn('bw16','bw','Who directed "Devdas" (2002)?',['Sanjay Leela Bhansali'],['Mahesh Bhatt','Ram Gopal Varma','Vidhu Vinod Chopra']),
      _btn('bw17','bw','What is the name of Shah Rukh Khan\'s production company?',['Red Chillies Entertainment'],['Excel Entertainment','Nadiadwala Grandson','T-Series']),
      _btn('bw18','bw','Which actress won National Award for "Gangubai Kathiawadi"?',['Alia Bhatt'],['Deepika Padukone','Tabu','Vidya Balan']),
      _btn('bw19','bw','Who plays Baahubali in the epic film?',['Prabhas'],['Rana Daggubati','Jr. NTR','Ram Charan']),
      _btn('bw20','bw','Which film shows the partition of India in 1947?',['Pinjar'],['Border','Veer-Zaara','Gadar']),
    ]),

    // ── Science ────────────────────────────────────────────────────
    _q('sc', 'Science Facts', 'Science', [
      _btn('sc1','sc','What is the speed of light?',['~3×10⁸ m/s'],['~3×10⁶ m/s','~3×10⁴ m/s','~3×10¹⁰ m/s']),
      _btn('sc2','sc','What is the atomic number of Carbon?',['6'],['4','8','12']),
      _btn('sc3','sc','Which gas is most abundant in Earth\'s atmosphere?',['Nitrogen'],['Oxygen','Carbon Dioxide','Argon']),
      _btn('sc4','sc','What is Newton\'s first law called?',['Law of Inertia'],['Law of Force','Law of Motion','Law of Gravity']),
      _btn('sc5','sc','What is the powerhouse of the cell?',['Mitochondria'],['Nucleus','Ribosome','Golgi Apparatus']),
      _btn('sc6','sc','Which planet has the most moons?',['Saturn'],['Jupiter','Uranus','Neptune']),
      _btn('sc7','sc','What is the boiling point of water at sea level (°C)?',['100'],['90','110','212']),
      _btn('sc8','sc','DNA stands for?',['Deoxyribonucleic Acid'],['Deoxyribose Nucleic Acid','Dibasic Nucleic Acid','Double Nucleic Acid']),
      _btn('sc9','sc','What type of bond involves sharing electrons?',['Covalent Bond'],['Ionic Bond','Metallic Bond','Hydrogen Bond']),
      _btn('sc10','sc','What is the unit of electric resistance?',['Ohm'],['Volt','Ampere','Watt']),
      _btn('sc11','sc','What is the chemical formula of table salt?',['NaCl'],['KCl','MgCl2','CaCl2']),
      _btn('sc12','sc','Which scientist proposed the theory of relativity?',['Albert Einstein'],['Isaac Newton','Niels Bohr','Max Planck']),
      _btn('sc13','sc','What is the process by which plants make food?',['Photosynthesis'],['Respiration','Transpiration','Osmosis']),
      _btn('sc14','sc','How many chromosomes do humans have?',['46'],['23','48','44']),
      _btn('sc15','sc','What is the hardest material known to science?',['Diamond'],['Graphene','Tungsten','Silicon Carbide']),
      _btn('sc16','sc','What force keeps planets in orbit?',['Gravity'],['Magnetism','Friction','Nuclear Force']),
      _btn('sc17','sc','What is the pH of pure water?',['7'],['5','8','6']),
      _btn('sc18','sc','Which organ produces insulin?',['Pancreas'],['Liver','Kidney','Spleen']),
      _btn('sc19','sc','What is the smallest unit of matter?',['Atom'],['Molecule','Electron','Quark']),
      _btn('sc20','sc','Which planet is closest to the Sun?',['Mercury'],['Venus','Earth','Mars']),
    ]),

    // ── IPL Cricket ────────────────────────────────────────────────
    _q('ipl', 'IPL Cricket', 'Cricket', [
      _btn('ipl1','ipl','Which team has won the most IPL titles?',['Mumbai Indians'],['Chennai Super Kings','Kolkata Knight Riders','Sunrisers Hyderabad']),
      _btn('ipl2','ipl','Who is the all-time leading run scorer in IPL?',['Virat Kohli'],['Rohit Sharma','Suresh Raina','David Warner']),
      _btn('ipl3','ipl','In which year was the IPL founded?',['2008'],['2006','2010','2005']),
      _btn('ipl4','ipl','Who has taken the most wickets in IPL history?',['Dwayne Bravo'],['Lasith Malinga','Yuzvendra Chahal','Sunil Narine']),
      _btn('ipl5','ipl','Which bowler delivered the first ball in IPL history?',['Zaheer Khan'],['Irfan Pathan','Anil Kumble','Harbhajan Singh']),
      _btn('ipl6','ipl','Which team is based in Kolkata?',['Kolkata Knight Riders'],['Rajasthan Royals','Punjab Kings','Delhi Capitals']),
      _btn('ipl7','ipl','Who was the first Orange Cap holder in IPL?',['Shaun Marsh'],['Sachin Tendulkar','Matthew Hayden','Virender Sehwag']),
      _btn('ipl8','ipl','Who hit the first six in IPL history?',['Brendon McCullum'],['Adam Gilchrist','Chris Gayle','Kevin Pietersen']),
      _btn('ipl9','ipl','What is the home ground of Mumbai Indians?',['Wankhede Stadium'],['Eden Gardens','Chinnaswamy Stadium','Feroz Shah Kotla']),
      _btn('ipl10','ipl','Who has scored the most centuries in IPL?',['Chris Gayle'],['Virat Kohli','Rohit Sharma','David Warner']),
      _btn('ipl11','ipl','Which IPL team uses the jersey color yellow?',['Chennai Super Kings'],['Mumbai Indians','Sunrisers Hyderabad','Kolkata Knight Riders']),
      _btn('ipl12','ipl','Who is "Universe Boss" in cricket?',['Chris Gayle'],['AB de Villiers','David Warner','Rohit Sharma']),
      _btn('ipl13','ipl','Which team won IPL 2023?',['Chennai Super Kings'],['Gujarat Titans','Mumbai Indians','Rajasthan Royals']),
      _btn('ipl14','ipl','Who is MS Dhoni\'s nickname?',['Captain Cool'],['Thala','Mahi','All of these'],fact:'Dhoni is called Captain Cool, Thala, and Mahi.'),
      _btn('ipl15','ipl','How many overs in an IPL match per side?',['20'],['15','25','10']),
      _btn('ipl16','ipl','Which player won the most Player of the Match awards in IPL?',['AB de Villiers'],['Chris Gayle','Rohit Sharma','Virat Kohli']),
      _btn('ipl17','ipl','Which IPL team\'s anthem is "Korbo Lorbo Jeetbo Re"?',['Kolkata Knight Riders'],['Chennai Super Kings','Mumbai Indians','Delhi Capitals']),
      _btn('ipl18','ipl','Who scored the highest individual score in an IPL innings?',['Brendon McCullum (158)'],['Chris Gayle (175)','AB de Villiers (133)','Virat Kohli (113)'],fact:'Chris Gayle holds the record with 175* in 2013.'),
      _btn('ipl19','ipl','Which team is nicknamed "Men in Blue and Gold"?',['Mumbai Indians'],['Rajasthan Royals','Chennai Super Kings','Punjab Kings']),
      _btn('ipl20','ipl','Who is the most expensive player ever bought in an IPL auction?',['Mitchell Starc'],['Sam Curran','Pat Cummins','Ben Stokes'],fact:'Mitchell Starc was sold for ₹24.75 crore at the IPL 2024 auction, surpassing Sam Curran (₹18.5 cr, 2023).'),
    ]),

    // ── History ────────────────────────────────────────────────────
    _q('hi', 'World History', 'History', [
      _btn('hi1','hi','In which year did World War II end?',['1945'],['1943','1944','1946']),
      _btn('hi2','hi','Who was the first President of the United States?',['George Washington'],['Thomas Jefferson','Abraham Lincoln','John Adams']),
      _btn('hi3','hi','The French Revolution began in which year?',['1789'],['1776','1804','1799']),
      _btn('hi4','hi','Who built the Great Wall of China?',['Emperor Qin Shi Huang (primarily)'],['Emperor Wu','Emperor Yongle','Emperor Xuanzong']),
      _btn('hi5','hi','Which empire was ruled by Julius Caesar?',['Roman Empire'],['Greek Empire','Ottoman Empire','Persian Empire']),
      _btn('hi6','hi','In which year did India gain independence?',['1947'],['1945','1950','1942']),
      _btn('hi7','hi','Who was the first man to walk on the Moon?',['Neil Armstrong'],['Buzz Aldrin','Yuri Gagarin','John Glenn']),
      _btn('hi8','hi','The Berlin Wall fell in which year?',['1989'],['1991','1987','1985']),
      _btn('hi9','hi','Who was known as the "Iron Lady"?',['Margaret Thatcher'],['Indira Gandhi','Angela Merkel','Hillary Clinton']),
      _btn('hi10','hi','Which ancient wonder was located in Alexandria?',['The Lighthouse'],['The Colossus','The Hanging Gardens','The Temple of Artemis']),
      _btn('hi11','hi','Who wrote the Communist Manifesto?',['Karl Marx & Friedrich Engels'],['Vladimir Lenin','Leon Trotsky','Joseph Stalin']),
      _btn('hi12','hi','The Titanic sank in which year?',['1912'],['1910','1914','1908']),
      _btn('hi13','hi','Which country launched the first artificial satellite?',['Soviet Union (USSR)'],['USA','Germany','China']),
      _btn('hi14','hi','Who was the first Emperor of China?',['Qin Shi Huang'],['Kublai Khan','Han Wudi','Tang Taizong']),
      _btn('hi15','hi','The Renaissance began in which country?',['Italy'],['France','England','Germany']),
      _btn('hi16','hi','Who discovered America in 1492?',['Christopher Columbus'],['Leif Erikson','Amerigo Vespucci','John Cabot']),
      _btn('hi17','hi','Which civilization built Machu Picchu?',['Inca'],['Maya','Aztec','Olmec']),
      _btn('hi18','hi','In which year did the Soviet Union dissolve?',['1991'],['1989','1993','1988']),
      _btn('hi19','hi','Who was the longest-reigning British monarch?',['Queen Elizabeth II'],['Queen Victoria','King George III','King Henry VIII']),
      _btn('hi20','hi','The Battle of Waterloo took place in which year?',['1815'],['1812','1820','1805']),
    ]),
  ];
}
