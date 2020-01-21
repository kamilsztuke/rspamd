--[[
Copyright (c) 2019, Vsevolod Stakhov <vsevolod@highsecure.ru>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]--

local function process_pdf_specific(task, part, specific)
  local suspicious_factor = 0
  if specific.encrypted then
    task:insert_result('PDF_ENCRYPTED', 1.0, part:get_filename())
    suspicious_factor = suspicious_factor + 0.1
    if specific.openaction then
      suspicious_factor = suspicious_factor + 0.5
    end
  end

  if specific.openaction and #specific.openaction > 10 then
    task:insert_result('PDF_JAVASCRIPT', 1.0, part:get_filename())
    suspicious_factor = suspicious_factor + 0.5
  end

  if specific.suspicious then
    suspicious_factor = suspicious_factor + 0.7
  end

  if suspicious_factor > 0.5 then
    if suspicious_factor > 1.0 then suspicious_factor = 1.0 end
    task:insert_result('PDF_SUSPICIOUS', suspicious_factor, part:get_filename())
  end
end

local tags_processors = {
  pdf = process_pdf_specific
}

local function process_specific_cb(task)
  local parts = task:get_parts() or {}

  for _,p in ipairs(parts) do
    if p:is_specific() then
      local data = p:get_specific()

      if data and type(data) == 'table' and data.tag then
        if tags_processors[data.tag] then
          tags_processors[data.tag](task, p, data)
        end
      end
    end
  end
end

local id = rspamd_config:register_symbol{
  type = 'callback',
  name = 'SPECIFIC_CONTENT_CHECK',
  callback = process_specific_cb
}

rspamd_config:register_symbol{
  type = 'virtual',
  name = 'PDF_ENCRYPTED',
  parent = id,
  groups = {"content", "pdf"},
}
rspamd_config:register_symbol{
  type = 'virtual',
  name = 'PDF_JAVASCRIPT',
  parent = id,
  groups = {"content", "pdf"},
}
rspamd_config:register_symbol{
  type = 'virtual',
  name = 'PDF_SUSPICIOUS',
  parent = id,
  groups = {"content", "pdf"},
}
