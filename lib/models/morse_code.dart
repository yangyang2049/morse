class MorseCode {
  final String character;
  final String morse;
  final String? description;

  const MorseCode({
    required this.character,
    required this.morse,
    this.description,
  });
}

class MorseCodeData {
  static const List<MorseCode> englishAlphabet = [
    MorseCode(character: 'A', morse: '.-', description: 'Alpha'),
    MorseCode(character: 'B', morse: '-...', description: 'Bravo'),
    MorseCode(character: 'C', morse: '-.-.', description: 'Charlie'),
    MorseCode(character: 'D', morse: '-..', description: 'Delta'),
    MorseCode(character: 'E', morse: '.', description: 'Echo'),
    MorseCode(character: 'F', morse: '..-.', description: 'Foxtrot'),
    MorseCode(character: 'G', morse: '--.', description: 'Golf'),
    MorseCode(character: 'H', morse: '....', description: 'Hotel'),
    MorseCode(character: 'I', morse: '..', description: 'India'),
    MorseCode(character: 'J', morse: '.---', description: 'Juliet'),
    MorseCode(character: 'K', morse: '-.-', description: 'Kilo'),
    MorseCode(character: 'L', morse: '.-..', description: 'Lima'),
    MorseCode(character: 'M', morse: '--', description: 'Mike'),
    MorseCode(character: 'N', morse: '-.', description: 'November'),
    MorseCode(character: 'O', morse: '---', description: 'Oscar'),
    MorseCode(character: 'P', morse: '.--.', description: 'Papa'),
    MorseCode(character: 'Q', morse: '--.-', description: 'Quebec'),
    MorseCode(character: 'R', morse: '.-.', description: 'Romeo'),
    MorseCode(character: 'S', morse: '...', description: 'Sierra'),
    MorseCode(character: 'T', morse: '-', description: 'Tango'),
    MorseCode(character: 'U', morse: '..-', description: 'Uniform'),
    MorseCode(character: 'V', morse: '...-', description: 'Victor'),
    MorseCode(character: 'W', morse: '.--', description: 'Whiskey'),
    MorseCode(character: 'X', morse: '-..-', description: 'X-ray'),
    MorseCode(character: 'Y', morse: '-.--', description: 'Yankee'),
    MorseCode(character: 'Z', morse: '--..', description: 'Zulu'),
  ];

  static const List<MorseCode> numbers = [
    MorseCode(character: '0', morse: '-----'),
    MorseCode(character: '1', morse: '.----'),
    MorseCode(character: '2', morse: '..---'),
    MorseCode(character: '3', morse: '...--'),
    MorseCode(character: '4', morse: '....-'),
    MorseCode(character: '5', morse: '.....'),
    MorseCode(character: '6', morse: '-....'),
    MorseCode(character: '7', morse: '--...'),
    MorseCode(character: '8', morse: '---..'),
    MorseCode(character: '9', morse: '----.'),
  ];

  static const List<MorseCode> punctuation = [
    MorseCode(character: '.', morse: '.-.-.-'),
    MorseCode(character: ',', morse: '--..--'),
    MorseCode(character: '?', morse: '..--..'),
    MorseCode(character: '!', morse: '-.-.--'),
    MorseCode(character: ':', morse: '---...'),
    MorseCode(character: ';', morse: '-.-.-.'),
    MorseCode(character: '=', morse: '-...-'),
    MorseCode(character: '+', morse: '.-.-.'),
    MorseCode(character: '-', morse: '-....-'),
    MorseCode(character: '_', morse: '..--.-'),
    MorseCode(character: '"', morse: '.-..-.'),
    MorseCode(character: '\'', morse: '.----.'),
    MorseCode(character: '(', morse: '-.--.'),
    MorseCode(character: ')', morse: '-.--.-'),
    MorseCode(character: '/', morse: '-..-.'),
    MorseCode(character: '@', morse: '.--.-.'),
  ];

  // 中文摩尔斯电码 - 常用汉字
  static const List<MorseCode> chineseCharacters = [
    MorseCode(character: '中', morse: '--..--'),
    MorseCode(character: '国', morse: '--.-'),
    MorseCode(character: '人', morse: '.-.-'),
    MorseCode(character: '大', morse: '-..'),
    MorseCode(character: '小', morse: '...-'),
    MorseCode(character: '上', morse: '..-'),
    MorseCode(character: '下', morse: '-..-'),
    MorseCode(character: '左', morse: '.-..'),
    MorseCode(character: '右', morse: '--.'),
    MorseCode(character: '前', morse: '.-.-.'),
    MorseCode(character: '后', morse: '---.'),
    MorseCode(character: '东', morse: '-...'),
    MorseCode(character: '西', morse: '...-'),
    MorseCode(character: '南', morse: '-.-'),
    MorseCode(character: '北', morse: '-..-'),
    MorseCode(character: '水', morse: '...'),
    MorseCode(character: '火', morse: '..-'),
    MorseCode(character: '山', morse: '.-'),
    MorseCode(character: '川', morse: '-.-.'),
    MorseCode(character: '日', morse: '.-.'),
    MorseCode(character: '月', morse: '--'),
    MorseCode(character: '天', morse: '-'),
    MorseCode(character: '地', morse: '-..'),
    MorseCode(character: '你', morse: '.-..'),
    MorseCode(character: '我', morse: '.--'),
    MorseCode(character: '他', morse: '-'),
    MorseCode(character: '她', morse: '.-'),
    MorseCode(character: '好', morse: '....'),
    MorseCode(character: '坏', morse: '--..'),
    MorseCode(character: '新', morse: '.-.-'),
    MorseCode(character: '旧', morse: '---'),
    MorseCode(character: '快', morse: '-.-.'),
    MorseCode(character: '慢', morse: '--.-'),
    MorseCode(character: '高', morse: '--.'),
    MorseCode(character: '低', morse: '-..'),
    MorseCode(character: '长', morse: '-.-'),
    MorseCode(character: '短', morse: '..-'),
    MorseCode(character: '多', morse: '-..'),
    MorseCode(character: '少', morse: '...'),
    MorseCode(character: '来', morse: '.-..'),
    MorseCode(character: '去', morse: '--.'),
    MorseCode(character: '进', morse: '.--'),
    MorseCode(character: '出', morse: '-.-'),
    MorseCode(character: '开', morse: '-.-'),
    MorseCode(character: '关', morse: '--.'),
    MorseCode(character: '学', morse: '.-.-'),
    MorseCode(character: '习', morse: '..-'),
    MorseCode(character: '工', morse: '--'),
    MorseCode(character: '作', morse: '--.'),
    MorseCode(character: '家', morse: '.--'),
    MorseCode(character: '庭', morse: '-.-'),
    MorseCode(character: '朋', morse: '.--.'),
    MorseCode(character: '友', morse: '--.-'),
    MorseCode(character: '爱', morse: '.-'),
    MorseCode(character: '情', morse: '--.'),
    MorseCode(character: '时', morse: '...'),
    MorseCode(character: '间', morse: '.--'),
    MorseCode(character: '年', morse: '-.-'),
    MorseCode(character: '春', morse: '-.-.'),
    MorseCode(character: '夏', morse: '--..'),
    MorseCode(character: '秋', morse: '--.-'),
    MorseCode(character: '冬', morse: '-..'),
  ];

  // 常用英文单词 - 用于单词练习
  static const List<MorseCode> commonWords = [
    // 3字母单词
    MorseCode(character: 'THE', morse: '- .... .', description: '定冠词'),
    MorseCode(character: 'AND', morse: '.- -. -..', description: '和'),
    MorseCode(character: 'FOR', morse: '..-. --- .-.', description: '为了'),
    MorseCode(character: 'ARE', morse: '.- .-. .', description: '是'),
    MorseCode(character: 'BUT', morse: '-... ..- -', description: '但是'),
    MorseCode(character: 'NOT', morse: '-. --- -', description: '不'),
    MorseCode(character: 'YOU', morse: '-.-- --- ..-', description: '你'),
    MorseCode(character: 'ALL', morse: '.- .-.. .-..', description: '全部'),
    MorseCode(character: 'CAN', morse: '-.-. .- -.', description: '能够'),
    MorseCode(character: 'HAD', morse: '.... .- -..', description: '有过'),
    MorseCode(character: 'HER', morse: '.... . .-.', description: '她的'),
    MorseCode(character: 'WAS', morse: '.-- .- ...', description: '是过'),
    MorseCode(character: 'ONE', morse: '--- -. .', description: '一'),
    MorseCode(character: 'OUR', morse: '--- ..- .-.', description: '我们的'),
    MorseCode(character: 'OUT', morse: '--- ..- -', description: '出去'),

    // 4字母单词
    MorseCode(character: 'THAT', morse: '- .... .- -', description: '那个'),
    MorseCode(character: 'WITH', morse: '.-- .. - ....', description: '和'),
    MorseCode(character: 'HAVE', morse: '.... .- ...- .', description: '有'),
    MorseCode(character: 'THIS', morse: '- .... .. ...', description: '这个'),
    MorseCode(character: 'WILL', morse: '.-- .. .-.. .-..', description: '将要'),
    MorseCode(character: 'YOUR', morse: '-.-- --- ..- .-.', description: '你的'),
    MorseCode(character: 'FROM', morse: '..-. .-. --- --', description: '从'),
    MorseCode(character: 'THEY', morse: '- .... . -.--', description: '他们'),
    MorseCode(character: 'KNOW', morse: '-.- -. --- .--', description: '知道'),
    MorseCode(character: 'WANT', morse: '.-- .- -. -', description: '想要'),
    MorseCode(character: 'BEEN', morse: '-... . . -.', description: '曾经'),
    MorseCode(character: 'GOOD', morse: '--. --- --- -..', description: '好的'),
    MorseCode(character: 'MUCH', morse: '-- ..- -.-. ....', description: '很多'),
    MorseCode(character: 'SOME', morse: '... --- -- .', description: '一些'),
    MorseCode(character: 'TIME', morse: '- .. -- .', description: '时间'),

    // 5字母单词
    MorseCode(
        character: 'WOULD', morse: '.-- --- ..- .-.. -..', description: '将会'),
    MorseCode(character: 'THERE', morse: '- .... . .-. .', description: '那里'),
    MorseCode(
        character: 'COULD', morse: '-.-. --- ..- .-.. -..', description: '能够'),
    MorseCode(character: 'OTHER', morse: '--- - .... . .-.', description: '其他'),
    MorseCode(character: 'AFTER', morse: '.- ..-. - . .-.', description: '之后'),
    MorseCode(
        character: 'FIRST', morse: '..-. .. .-. ... -', description: '第一'),
    MorseCode(character: 'NEVER', morse: '-. . ...- . .-.', description: '从不'),
    MorseCode(character: 'THESE', morse: '- .... . ... .', description: '这些'),
    MorseCode(character: 'THINK', morse: '- .... .. -. -.', description: '思考'),
    MorseCode(character: 'WHERE', morse: '.-- .... . .-. .', description: '哪里'),
    MorseCode(character: 'BEING', morse: '-... . .. -. --.', description: '存在'),
    MorseCode(
        character: 'EVERY', morse: '. ...- . .-. -.--', description: '每个'),
    MorseCode(character: 'GREAT', morse: '--. .-. . .- -', description: '伟大'),
    MorseCode(character: 'MIGHT', morse: '-- .. --. .... -', description: '可能'),
    MorseCode(
        character: 'SHALL', morse: '... .... .- .-.. .-..', description: '应该'),
  ];

  static List<MorseCode> getAllCodes() {
    return [
      ...englishAlphabet,
      ...numbers,
      ...punctuation,
      ...chineseCharacters,
    ];
  }

  static String? textToMorse(String text) {
    final codes = getAllCodes();
    final result = <String>[];

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      // 为了大小写不敏感匹配，将英文字母统一转换为大写再查表
      final searchChar = char.toUpperCase();
      if (char == ' ') {
        result.add('/');
        continue;
      }

      final code = codes.firstWhere(
        (code) => code.character == searchChar,
        orElse: () => MorseCode(character: char, morse: char),
      );

      if (code.morse != char) {
        result.add(code.morse.replaceAll('.', '·'));
      } else {
        result.add(char);
      }

      if (i < text.length - 1 && text[i + 1] != ' ') {
        result.add(' ');
      }
    }

    return result.join('');
  }

  static String? morseToText(String morse) {
    final codes = getAllCodes();
    // 统一将中点(·)替换回英文点('.') 再解析
    final normalized = morse.replaceAll('·', '.');
    final words = normalized.split('/');
    final result = <String>[];

    for (final word in words) {
      final letters = word.trim().split(' ');
      final wordResult = <String>[];

      for (final letter in letters) {
        if (letter.isEmpty) continue;

        final code = codes.firstWhere(
          (code) => code.morse == letter,
          orElse: () => MorseCode(character: letter, morse: letter),
        );

        wordResult.add(code.character);
      }

      result.add(wordResult.join(''));
    }

    return result.join(' ');
  }
}
