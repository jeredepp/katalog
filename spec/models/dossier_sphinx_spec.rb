require 'spec_helper'

describe Dossier do
  describe '.split_search_words' do
    it 'should detect empty search' do
      Dossier.split_search_words('').should == [[], [], []]
      Dossier.split_search_words('   ').should == [[], [], []]
    end

    it 'should detect signatures' do
      Dossier.split_search_words('77.0').should == [['77.0'], [], []]
      Dossier.split_search_words('77.0 77.0.100 77.0.10 7 77.0.1').should == [['77.0', '77.0.100', '77.0.10', '7', '77.0.1'], [], []]
    end

    it 'should detect words' do
      Dossier.split_search_words('test new').should == [[], %w(test new), []]
      Dossier.split_search_words('test, new').should == [[], %w(test new), []]
      Dossier.split_search_words('test. new').should == [[], %w(test new), []]
    end

    it 'should detect signatures and words' do
      assert_equal [['77.0'], %w(test new), []], Dossier.split_search_words('test. 77.0, new')
      assert_equal [['77.0.1', '77.2'], %w(haha bla), []], Dossier.split_search_words('haha. 77.0.1, bla 77.2')
    end

    it 'should detect year' do
      assert_equal [[], ['1979'], []], Dossier.split_search_words('1979')
      assert_equal [[], ['2012'], []], Dossier.split_search_words('2012')
    end

    it 'should detect double quote sentences' do
      assert_equal [[], [], ['one']], Dossier.split_search_words('"one"')
      assert_equal [[], [], ['one two']], Dossier.split_search_words('"one two"')
      assert_equal [[], %w(before between last), ['one two', 'next, two']], Dossier.split_search_words('before, "one two" between "next, two" last')
    end
  end

  context '.build_query' do
    it 'should add * to signature searches' do
      assert_equal '@signature ("^7*")', Dossier.build_query('7')
      assert_equal '@signature ("^77.0.10*")', Dossier.build_query('77.0.10')
    end

    it 'should add no * to short search words' do
      assert_match /[^*]a[^*]/, Dossier.build_query('nr a history')
    end

    it 'should use literal and trailing * search for medium short search words' do
      assert_match /"nr" \| "nr\*"/, Dossier.build_query('nr a history')
    end

    it 'should add surrounding * to non-short search words' do
      assert_match /\*history\*/, Dossier.build_query('nr as history')
    end

    it 'should not include alternative word forms for words' do
      assert_no_match /Nationalrat/, Dossier.build_query('nr')
    end

    it 'should build a signature range' do
      query = Dossier.build_query('7. - 77.0.200')
      assert_match '@signature ("^77.0.200*")', query
      assert_match '|', query
      assert_no_match /@signature ("^77.0.999*")/, query
    end
  end

  context '.by_text' do
    it 'should work with & and +' do
      require 'thinking_sphinx/test'

      ThinkingSphinx::Test.run do
        expect { Dossier.by_text('&').count }.to_not raise_exception
        expect { Dossier.by_text('+').count }.to_not raise_exception
      end
    end
  end
end
