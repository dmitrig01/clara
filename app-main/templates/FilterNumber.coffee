<select class="filter-op" name="filter-op-<%= index %>" id="filter-op-<%= index %>">
  <option value="eq"<%= (filter.get('op') == 'eq' ? ' selected' : '') %>>=</option>
  <option value="lt"<%= (filter.get('op') == 'lt' ? ' selected' : '') %>>&lt;</option>
  <option value="gt"<%= (filter.get('op') == 'gt' ? ' selected' : '') %>>&gt;</option>
</select>
<input type="text" class="filter-input" name="filter-<%= index %>" value="<%= filter.get('value') %>" id="filter-<%= index %>">
