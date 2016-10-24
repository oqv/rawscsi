module Rawscsi
  module Query
    class Compound
      include Rawscsi::Stringifier::Encode

      attr_reader :query_hash
      def initialize(query_hash)
        @query_hash = query_hash
      end

      def build
        [
          query,
          weights,
          distance,
          date,
          sort,
          start,
          limit,
          fields,
          facets,
          cursor,
          "q.parser=structured"
        ].compact.join("&")
      end

      private
      def query
        "q=" + Rawscsi::Query::Stringifier.new(query_hash[:q]).build
      end

      def date
        return nil unless date_hash = query_hash[:date]
        output_str = "fq="
        date_hash.each do |k,v|
          output_str << "#{k}:#{FRC3339(v)}"
        end
        encode(output_str)
      end

      def FRC3339(date_str)
        return date_str if /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/ =~ date_str
        date_str.gsub(/\d{4}-\d{2}-\d{2}/) do |dt|
          "#{dt}T00:00:00Z"
        end
      end

      def sort
        return nil unless query_hash[:sort]
        encode("sort=#{query_hash[:sort]}")
      end

      def distance
        return nil unless location = query_hash[:location]
        "expr.distance=haversin(#{location[:latitude]},#{location[:longitude]},location.latitude,location.longitude)"
      end

      def weights
        return nil unless weights = query_hash[:weights]
        # "q.options=#{URI.decode(CGI.escape(weights.to_s))}"
        "q.options=#{CGI.escape(weights)}"
      end

      def start
        return nil unless query_hash[:start]
        "start=#{query_hash[:start]}"
      end

      def limit
        return nil unless query_hash[:limit]
        "size=#{query_hash[:limit]}"
      end

      def facets
        return nil unless facets_array = query_hash[:facets]
        facets_str = ''
        facets_array = facets_array.split(',')
        append_and = facets_array.size > 1
        facets_array.each do |facet|
          splitted = facet.split(':')
          key = splitted[0]
          value = nil
          if splitted.size > 1
            value = "{sort: '#{splitted[1].to_s}',size: 10000}"
          else
            value = "{size: 1000}"
          end

          if append_and
            facets_str << "facet.#{key.to_s}=#{value}&"
          else
            facets_str << "facet.#{key.to_s}=#{value}"
          end
        end
        encode(facets_str)
      end

      def fields
        return nil unless fields_array = query_hash[:fields]
        output = []
        fields_array.each do |field_sym|
          output << field_sym.to_s
        end
        "return=" + output.join(",")
      end

      def cursor
        return nil unless query_hash[:cursor]
        "cursor=#{query_hash[:cursor]}"
      end
   end
  end
end
