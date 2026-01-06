/**
 * 课程分组数据
 * 用于字母和数字的分组学习
 */
export class LessonGroups {
  // 字母分组：每3个字母一组
  static getAlphabetGroups(): string[][] {
    return [
      ['A', 'B', 'C'],
      ['D', 'E', 'F'],
      ['G', 'H', 'I'],
      ['J', 'K', 'L'],
      ['M', 'N', 'O'],
      ['P', 'Q', 'R'],
      ['S', 'T', 'U'],
      ['V', 'W', 'X'],
      ['Y', 'Z']
    ]
  }

  // 数字分组：每3个数字一组
  static getNumberGroups(): string[][] {
    return [
      ['0', '1', '2'],
      ['3', '4', '5'],
      ['6', '7', '8'],
      ['9']
    ]
  }
}



