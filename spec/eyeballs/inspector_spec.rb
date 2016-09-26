require 'spec_helper'

describe Eyeballs::Inspector do

  let(:foo){ Foo.all.eyeballs }
  let(:foo_bar) do
    Foo.all.preload(:bars).eyeballs
  end

  # describe :inspect do
  #   context :foo do
  #     it 'outputs the query plan' do
  #       expect(foo.inspect).to include 'EXPLAIN for: SELECT "foos".* FROM "foos"'
  #     end
  #   end
  #
  #   context :foo_bar do
  #     it 'outputs the query plan' do
  #       expect(foo_bar.inspect).to include 'EXPLAIN for: SELECT "foos".* FROM "foos"'
  #       expect(foo_bar.inspect).to include 'EXPLAIN for: SELECT "bars".* FROM "bars"'
  #     end
  #   end
  # end

  describe :queries do
    context :foo do
      it 'returns array of queries' do
        expect(foo.queries.length).to eql 1
        expect(foo.queries[0]).to include 'SELECT "foos".* FROM "foos"'
      end
    end

    context :foo_bar do
      it 'returns array of queries' do
        expect(foo_bar.queries.length).to eql 2 
        expect(foo_bar.queries[0]).to include 'SELECT "foos".* FROM "foos"'
        expect(foo_bar.queries[1]).to include 'SELECT "bars".* FROM "bars"'
      end
    end
  end

  describe :to_s do
    it 'displays class string' do
      expect(foo.to_s).to include 'Eyeballs::Inspector: #<Foo::ActiveRecord_Relation:0x'
    end
  end

  describe :explain_queries do
    it 'validates format' do
      expect { foo.explain_queries(format: :toml) }.to raise_error Eyeballs::UnknownFormatError 
    end

    it 'validates options' do
      expect { foo.explain_queries(options: [:analyze, :explain]) }.to raise_error Eyeballs::UnknownOptionError
    end

    it 'generates explain queries' do
      expect(foo.explain_queries).to eql [
        "EXPLAIN (ANALYZE,VERBOSE,COSTS,BUFFERS,FORMAT TEXT) SELECT \"foos\".* FROM \"foos\""
      ]
    end

    it 'generates explain queries for multiple queries' do
      expect(foo_bar.explain_queries).to eql [
        "EXPLAIN (ANALYZE,VERBOSE,COSTS,BUFFERS,FORMAT TEXT) SELECT \"foos\".* FROM \"foos\"",
        "EXPLAIN (ANALYZE,VERBOSE,COSTS,BUFFERS,FORMAT TEXT) SELECT \"bars\".* FROM \"bars\" WHERE \"bars\".\"foo_id\" IN (1)"
      ]
    end

    it 'generates explain query given options and format' do
      expect(foo.explain_queries(format: :json, options: [:analyze])).to eql [
        "EXPLAIN (ANALYZE,FORMAT JSON) SELECT \"foos\".* FROM \"foos\""
      ]
    end
  end

  describe :explain do
    it 'runs explain query' do
      explain_array = foo.explain
      expect(explain_array.length).to eql 1
      expect(explain_array[0]).to include "Seq Scan on public.foos  (cost="
    end

    it 'runs explain queries' do
      explain_array = foo_bar.explain
      expect(explain_array.length).to eql 2
      expect(explain_array[0]).to include "Seq Scan on public.foos  (cost="
      expect(explain_array[1]).to include "Seq Scan on public.bars  (cost="
    end
  end

end
