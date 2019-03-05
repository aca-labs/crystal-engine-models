# require "elasticsearch-crystal"

# class Engine::Elastic(T)

#     HOST = ENV["ES_HOST"]? || "localhost"
#     PORT =  ENV["ES_PORT"]?.try(&.to_i) || 9200

#     # Singleton ES client
#     @@client ||= Elasticsearch::API::Client.new({ host: HOST, port: PORT, reload_connections: true })

#     def self.search(*args)
#         @@client.search(*args)
#     end

#     def self.count(*args)
#         @@client.count(*args)
#     end

#     def self.client
#         @@client
#     end

#     COUNT = "count"
#     HITS = "hits"
#     TOTAL = "total"
#     ID = "id"
#     SCORE = ["_score"]
#     INDEX = (ENV["ELASTIC_INDEX"]? || "default")

#     def initialize(**opts)
#         @filter = T.table_name
#         @index = opts[:index] || INDEX
#     end

#     # Safely build the query
#     def query(params = nil, filters = nil)
#         builder = Elastic::Query.new(params)
#         builder.filter(filters) if filters
#         builder
#     end

#     def search(builder, &block)
#         query = generate_body(builder)

#         # If a formatter block is supplied, each loaded record is passed to it
#         # allowing annotation/conversion of records using data from the model
#         # and current request (e.g groups are annotated with "admin" if the
#         # currently logged in user is an admin of the group).
#         # Nils are removed from the list.

#         result = self.class.search(query)
#         ids = result[HITS][HITS].to_a.map { |entry| entry[ID] }
#         records = T.find_all(ids).to_a

#         # Yield record to transform if block given
#         results = if block
#             records.map { |rec| yield rec }.compact
#         else
#             records
#         end

#         # Ensure the total is accurate
#         total = result[HITS][TOTAL] || 0

#         # Adjust for compaction
#         total = total - (records.length - results.length)

#         # We check records against limit (pre-compaction) and total against actual result length
#         # Worst case senario is there is one additional request for results at an offset that returns no results.
#         # The total results number will be accurate on the final page of results from the clients perspective.
#         total = results.length + builder.offset if records.length < builder.limit && total > (results.length + builder.offset)

#         {
#             total: total,
#             results: results
#         }
#     end

#     def count(builder)
#         query = generate_body(builder)

#         # Simplify the query
#         query[:body].delete(:from)
#         query[:body].delete(:size)
#         query[:body].delete(:sort)

#         Elastic(T).count(query)[COUNT]
#     end

#     def generate_body(builder)
#         opt = builder.build
#         sort = (opt[:sort] || [] of String) + SCORE

#         queries = opt[:queries] || [] of String
#         queries.unshift(opt[:query])

#         filters = opt[:filters] || [] of String

#         if @filter
#             if @use_couch_type
#                 filters.unshift({term: {"doc.type" => @filter}})
#             else
#                 filters.unshift({type: {value: @filter}})
#             end
#         end

#         {
#             index: @index,
#             body: {
#                 sort: sort,
#                 query: {
#                     bool: {
#                         must: {
#                             query: {
#                                 bool: {
#                                     must: queries
#                                 }
#                             }
#                         },
#                         filter: {
#                             bool: {
#                                 must: filters
#                             }
#                         }
#                     }
#                 },
#                 from: opt[:offset],
#                 size: opt[:limit]
#             }
#         }
#     end

#     class Query

#         def initialize(params = nil)
#             query = params ? params.permit(:q, :limit, :offset) : {} of

#             @filters = nil
#             @search = "#{query[:q]}*"
#             @fields = ["_all".freeze]

#             @limit = query[:limit] || 20
#             @limit = @limit.to_i
#             @limit = 500 if @limit > 500

#             @offset = query[:offset] || 0
#             @offset = offset.to_i
#             @offset = 10000 if offset > 10000
#         end

#         property :offset, :limit, :sort, :fields, :query_settings

#         def raw_filter(filter)
#             @raw_filter ||= [] of String
#             @raw_filter << filter
#             self
#         end

#         def search_field(field)
#             @fields.unshift(field)
#         end

#         # filters is in the form {fieldname1: ["var1","var2",...], fieldname2: ["var1","var2"...]}
#         # NOTE:: may overwrite an existing filter in merge
#         def filter(filters)
#             @filters ||= {} of Symbol => Array(String)
#             @filters.merge!(filters)
#             self
#         end

#         # Like filter however all keys are OR's instead of AND's
#         def or_filter(filters)
#             @orFilter ||= {} of Symbol => Array(String)
#             @orFilter.merge!(filters)
#             self
#         end

#         def and_filter(filters)
#             @andFilter ||= {} of Symbol => Array(String)
#             @andFilter.merge!(filters)
#             self
#         end

#         # Applys the query to child objects
#         def has_child(name)
#             @hasChild = name
#         end

#         def has_parent(name)
#             @hasParent = name
#         end

#         def range(filter)
#             @rangeFilter ||= [] of String
#             @rangeFilter << filter
#             self
#         end

#         # Call to add fields that should be missing
#         # Effectively adds a filter that ensures a field is missing
#         def missing(*fields)
#             @missing ||= Set.new
#             @missing.merge(fields)
#             self
#         end

#         # The opposite of filter
#         def not(filters)
#             @nots ||= {}
#             @nots.merge!(filters)
#             self
#         end

#         def exists(*fields)
#             @exists ||= Set.new
#             @exists.merge(fields)
#             self
#         end

#         def build
#             if @filters
#                 fieldfilters = []

#                 @filters.each do |key, value|
#                     fieldfilter = { :or => [] }
#                     build_filter(fieldfilter[:or], key, value)

#                     # TODO:: Discuss this - might be a security issue
#                     unless fieldfilter[:or].empty?
#                         fieldfilters.push(fieldfilter)
#                     end
#                 end
#             end

#             if @orFilter
#                 fieldfilters ||= [] of String
#                 fieldfilter = { :or => [] of String }
#                 orArray = fieldfilter[:or]

#                 @orFilter.each do |key, value|
#                     build_filter(orArray, key, value)
#                 end

#                 unless orArray.empty?
#                     fieldfilters.push(fieldfilter)
#                 end
#             end

#             if @andFilter
#                 fieldfilters ||= [] of String
#                 fieldfilter = { :and => [] of String}
#                 andArray = fieldfilter[:and]

#                 @andFilter.each do |key, value|
#                     build_filter(andArray, key, value)
#                 end

#                 unless andArray.empty?
#                     fieldfilters.push(fieldfilter)
#                 end
#             end

#             if @rangeFilter
#                 fieldfilters ||= [] of String

#                 @rangeFilter.each do |value|
#                     fieldfilters.push({range: value})
#                 end
#             end

#             if @nots
#                 fieldfilters ||= [] of String

#                 @nots.each do |key, value|
#                     fieldfilter = { not: { filter: { or: [] of String } } }
#                     build_filter(fieldfilter[:not][:filter][:or], key, value)
#                     unless fieldfilter[:not][:filter][:or].empty?
#                         fieldfilters.push(fieldfilter)
#                     end
#                 end
#             end

#             if @missing
#                 fieldfilters ||= [] of String

#                 @missing.each do |field|
#                     fieldfilters.push({
#                         missing: { field: field }
#                     })
#                 end
#             end

#             if @exists
#                 fieldfilters ||= [] of String

#                 @exists.each do |field|
#                     fieldfilters.push({
#                         exists: { field: field }
#                     })
#                 end
#             end

#             if @raw_filter
#                 fieldfilters ||= [] of String
#                 fieldfilters += @raw_filter
#             end

#             if @search.length > 1
#                 # Break the terms up purely on whitespace
#                 query_obj = nil

#                 if @hasChild || @hasParent
#                     should = [{
#                             simple_query_string: {
#                                 query: @search,
#                                 fields: @fields
#                             }
#                         }]

#                     if @query_settings
#                         should[0][:simple_query_string].merge! @query_settings
#                     end

#                     if @hasChild
#                         should << {
#                                 has_child: {
#                                     type: @hasChild,
#                                     query: {
#                                         simple_query_string: {
#                                             query: @search,
#                                             fields: @fields
#                                         }
#                                     }
#                                 }
#                             }
#                     end

#                     if @hasParent
#                         should << {
#                                 has_parent: {
#                                     parent_type: @hasParent,
#                                     query: {
#                                         simple_query_string: {
#                                             query: @search,
#                                             fields: @fields
#                                         }
#                                     }
#                                 }
#                             }
#                     end

#                     query_obj = {
#                         query: {
#                             bool: {
#                                 should: should
#                             }
#                         },
#                         filters: fieldfilters,
#                         offset: @offset,
#                         limit: @limit
#                     }
#                 else
#                     query_obj = {
#                         query: {
#                             simple_query_string: {
#                                 query: @search,
#                                 fields: @fields
#                             }
#                         },
#                         filters: fieldfilters,
#                         offset: @offset,
#                         limit: @limit
#                     }
#                 end

#                 query_obj
#             else
#                 {
#                     sort: @sort || DEFAULT_SORT,
#                     filters: fieldfilters,
#                     query: {
#                         match_all: {}
#                     },
#                     offset: @offset,
#                     limit: @limit
#                 }
#             end
#         end

#         DEFAULT_SORT = [{
#             "doc.created_at" => {
#                 order: :desc
#             }
#         }]

#         protected def build_filter(filters, key, values)
#             values.each { |var|
#                 if var.nil?
#                     filters.push({
#                         missing: { field: key }
#                     })
#                 else
#                     filters.push({
#                         :term => {
#                             key => var
#                         }
#                     })
#                 end
#             }
#         end
#     end
# end
