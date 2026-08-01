import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { CourseCatalogV2, CourseId } from '../main/ets/data/CourseCatalogV2';
import { LocalLearningSettings } from '../main/ets/store/LocalLearningSettings';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });
    it('assertContain', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'abc';
      let b = 'b';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });

    it('courseCatalogUsesStableTwentyFourIds', 0, () => {
      const courses = CourseCatalogV2.getAll();
      const ids = courses.map(course => course.id);
      expect(courses.length).assertEqual(24);
      expect(new Set(ids).size).assertEqual(24);
      expect(ids.includes(CourseId.ALPHABET_REVIEW_A_L)).assertTrue();
      expect(ids.includes(CourseId.PUNCTUATION_REVIEW)).assertTrue();
    });

    it('chineseKnowledgeCourseIsOnlyVisibleForChinese', 0, () => {
      expect(CourseCatalogV2.getVisible('en-US').length).assertEqual(23);
      expect(CourseCatalogV2.getVisible('fr-FR').length).assertEqual(23);
      expect(CourseCatalogV2.getVisible('zh-CN').length).assertEqual(24);
      expect(CourseCatalogV2.getVisible('zh-HK').length).assertEqual(24);
    });

    it('reviewCoursesRequireOnePassAndHaveExpectedItems', 0, () => {
      const alphabetReview = CourseCatalogV2.get(CourseId.ALPHABET_REVIEW_A_L);
      const numbersReview = CourseCatalogV2.get(CourseId.NUMBERS_REVIEW);
      expect(alphabetReview?.kind).assertEqual('review');
      expect(alphabetReview?.items.length).assertEqual(12);
      expect(numbersReview?.items.length).assertEqual(10);
    });

    it('repetitionCountIsClampedFromOneToFive', 0, () => {
      expect(LocalLearningSettings.clampRepetitionCount(-1)).assertEqual(1);
      expect(LocalLearningSettings.clampRepetitionCount(3)).assertEqual(3);
      expect(LocalLearningSettings.clampRepetitionCount(10)).assertEqual(5);
    });
  });
}
