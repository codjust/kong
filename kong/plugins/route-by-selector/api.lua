local crud = require "kong.api.crud_helpers"
local utils = require "kong.tools.utils"
local response = kong.response

--TODO: check params valid
return {
    -- ["/consumers/:username_or_id/route-by-selector/"] = {
    --     before = function(self, dao_factory, helpers)
    --         crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
    --         self.params.consumer_id = self.consumer.id
    --     end,
    --     GET = function(self, dao_factory)
    --         crud.paginated_set(self, dao_factory.route_by_selector)
    --     end,
    --     PUT = function(self, dao_factory)
    --         crud.put(self.params, dao_factory.route_by_selector)
    --     end,
    --     POST = function(self, dao_factory)
    --         crud.post(self.params, dao_factory.route_by_selector)
    --     end
    -- },
    -- ["/consumers/:username_or_id/route-by-selector/:name_or_id"] = {
    --     before = function(self, dao_factory, helpers)
    --         crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
    --         self.params.consumer_id = self.consumer.id
    --         local selectors, err =
    --             crud.find_by_id_or_field(
    --             dao_factory.route_by_selector,
    --             {name = ngx.unescape_uri(self.params.name_or_id)},
    --             self.params.consumer_id,
    --             "consumer_id"
    --         )
    --         if err then
    --             return helpers.yield_error(err)
    --         elseif next(selectors) == nil then
    --             return helpers.responses.send_HTTP_NOT_FOUND()
    --         end
    --         self.params.id = nil
    --         self.params.name_or_id = nil
    --         self.selector = selectors[1]
    --     end,
    --     GET = function(self, dao_factory, helpers)
    --         return helpers.responses.send_HTTP_OK(self.selector)
    --     end,
    --     PATCH = function(self, dao_factory)
    --         local cjson = require("cjson")
    --         kong.log.debug("comsumers PATCH params: ", cjson.encode(self.params))
    --         ngx.update_time()
    --         self.params.op_time = ngx.now()
    --         crud.patch(self.params, dao_factory.route_by_selector, self.selector)
    --     end,
    --     DELETE = function(self, dao_factory)
    --         crud.delete(self.selector, dao_factory.route_by_selector)
    --     end
    -- },
    ["/route-by-selector/"] = {
        before = function(self, dao_factory, helpers)
            local method = ngx.req.get_method()
            if method == 'GET' then 
                return
            end
            local db_service = kong.db.services
            -- service_id service_name
            local service_id = self.params.service_id
            local service_name = self.params.service_name

            local service
            if service_id and utils.is_valid_uuid(service_id) then
                service, _, err = db_service:select({id = service_id})
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                if not service_name then
                    return helpers.responses.send_HTTP_NOT_FOUND("Not found params service_id or service_name in body.")
                end
                service, _, err = db_service:select_by_name(service_name)
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                return helpers.responses.send_HTTP_NOT_FOUND("Not found service.")
            end

            self.params.service_id = service.id
            self.params.service_name = service.name
        end,
        GET = function(self, dao_factory)
            crud.paginated_set(self, dao_factory.route_by_selector)
        end,
        PUT = function(self, dao_factory)
            crud.put(self.params, dao_factory.route_by_selector)
        end,
        POST = function(self, dao_factory)
            local cjson = require("cjson")
            kong.log.debug("POST params: ", cjson.encode(self.params))
            crud.post(self.params, dao_factory.route_by_selector)
        end
    },
    ["/route-by-selector/:selector_id_or_name"] = {
        before = function(self, dao_factory, helpers)
            local selector_id_or_name = self.params.selector_id_or_name

            local selectors, err
            if utils.is_valid_uuid(selector_id_or_name) then
                selectors, err =
                    crud.find_by_id_or_field(
                    dao_factory.route_by_selector,
                    {id = ngx.unescape_uri(self.params.selector_id_or_name)},
                    ngx.unescape_uri(self.params.selector_id_or_name),
                    "id"
                )
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not selectors then
                selectors, err =
                    crud.find_by_id_or_field(
                    dao_factory.route_by_selector,
                    {selector_name = ngx.unescape_uri(self.params.selector_name)},
                    ngx.unescape_uri(self.params.selector_name),
                    "selector_name"
                )
            end

            if err then
                return helpers.yield_error(err)
            elseif next(selectors) == nil then
                return helpers.responses.send_HTTP_NOT_FOUND()
            end

            self.selector = selectors[1]
            self.selector_name = nil

            local method = ngx.req.get_method()
            if method == 'GET' or method == 'DELETE'then 
                return
            end
            local db_service = kong.db.services
            -- service_id service_name
            local service_id = self.params.service_id
            local service_name = self.params.service_name

            local service
            if service_id and utils.is_valid_uuid(service_id) then
                service, _, err = db_service:select({id = service_id})
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                if not service_name then
                    return helpers.responses.send_HTTP_NOT_FOUND("Not found params service_id or service_name in body.")
                end
                service, _, err = db_service:select_by_name(service_name)
                if err then
                    return helpers.yield_error(err)
                end
            end

            if not service then
                return helpers.responses.send_HTTP_NOT_FOUND("Not found service.")
            end

            self.params.service_id = service.id
            self.params.service_name = service.name
            self.params.selector_id_or_name = nil
        end,
        GET = function(self, dao_factory, helpers)
            return helpers.responses.send_HTTP_OK(self.selector)
        end,
        PATCH = function(self, dao_factory)
            local cjson = require("cjson")
            kong.log.debug("PATCH params: ", cjson.encode(self.params))
            ngx.update_time()
            self.params.op_time = ngx.now()
            crud.patch(self.params, dao_factory.route_by_selector, self.selector)
        end,
        DELETE = function(self, dao_factory)
            crud.delete(self.selector, dao_factory.route_by_selector)
        end
    }
    --,
    -- ["/services/:name_or_id/route-by-selector/"] = {
    --     before = function(self, dao_factory, helpers)
    --         local db_service = kong.db.services
    --         local name_or_id = self.params.name_or_id
    --         local service
    --         if utils.is_valid_uuid(name_or_id) then
    --             service, _, err = db_service:select({id = name_or_id})
    --             if err then
    --                 return helpers.yield_error(err)
    --             end
    --         end
    --         if not service then
    --             service, _, err = db_service:select_by_name(name_or_id)
    --             if err then
    --                 return helpers.yield_error(err)
    --             end
    --         end
    --         if not service then
    --             return helpers.responses.send_HTTP_NOT_FOUND( "not found service in name_or_id.")
    --         end
    --         self.params.service_id = service.id
    --         self.params.name_or_id = nil
    --         local selectors, err =
    --             crud.find_by_id_or_field(
    --             dao_factory.route_by_selector,
    --             {service_id = self.params.service_id},
    --             ngx.unescape_uri(self.params.service_id),
    --             "service_id"
    --         )
    --         if err then
    --             return helpers.yield_error(err)
    --         elseif next(selectors) == nil then
    --             return helpers.responses.send_HTTP_NOT_FOUND()
    --         end
    --         self.selector = selectors[1]
    --     end,
    --     GET = function(self, dao_factory, helpers)
    --         crud.paginated_set(self, dao_factory.route_by_selector)
    --     end,
    --     PATCH = function(self, dao_factory)
    --         local cjson = require("cjson")
    --         kong.log.debug("PATCH params: ", cjson.encode(self.params))
    --         ngx.update_time()
    --         self.params.op_time = ngx.now()
    --         crud.patch(self.params, dao_factory.route_by_selector, self.selector)
    --     end,
    --     POST = function(self, dao_factory)
    --         local cjson = require("cjson")
    --         kong.log.debug("post params: ", cjson.encode(self.params))
    --         crud.post(self.params, dao_factory.route_by_selector)
    --     end
    -- },
    -- ["/services/:name_or_id/route-by-selector/:selctor_name_or_id"] = {
    --     before = function(self, dao_factory, helpers)
    --         local db_service = kong.db.services
    --         local name_or_id = self.params.name_or_id
    --         local service
    --         if utils.is_valid_uuid(name_or_id) then
    --             service, _, err = db_service:select({id = name_or_id})
    --             if err then
    --                 return helpers.yield_error(err)
    --             end
    --         end
    --         if not service then
    --             service, _, err = db_service:select_by_name(name_or_id)
    --             if err then
    --                 return helpers.yield_error(err)
    --             end
    --         end
    --         self.params.service_id = service.id
    --         self.params.name_or_id = nil
    --         local selectors, err =
    --             crud.find_by_id_or_field(
    --             dao_factory.route_by_selector,
    --             {name = ngx.unescape_uri(self.params.selctor_name_or_id)},
    --             ngx.unescape_uri(self.params.service_id),
    --             "service_id"
    --         )
    --         if err then
    --             return helpers.yield_error(err)
    --         elseif next(selectors) == nil then
    --             return helpers.responses.send_HTTP_NOT_FOUND()
    --         end
    --         self.params.selctor_name_or_id = nil
    --         self.selector = selectors[1]
    --         kong.log.debug("self.params.service_id: ", self.params.service_id)
    --     end,
    --     --TODO: check params valid
    --     GET = function(self, dao_factory, helpers)
    --         return helpers.responses.send_HTTP_OK(self.selector)
    --     end,
    --     PATCH = function(self, dao_factory)
    --         local cjson = require("cjson")
    --         kong.log.debug("PATCH params: ", cjson.encode(self.params))
    --         ngx.update_time()
    --         self.params.op_time = ngx.now()
    --         crud.patch(self.params, dao_factory.route_by_selector, self.selector)
    --     end,
    --     POST = function(self, dao_factory)
    --         local cjson = require("cjson")
    --         kong.log.debug("post params: ", cjson.encode(self.params))
    --         crud.post(self.params, dao_factory.route_by_selector)
    --     end,
    --     DELETE = function(self, dao_factory)
    --         crud.delete(self.selector, dao_factory.route_by_selector)
    --     end
    -- }
}
