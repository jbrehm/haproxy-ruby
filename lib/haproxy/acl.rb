module HAProxy
  module Acl

    #TODO Tests
    #TODO Better error handling and result validation

    def show_acls(key = 'id')
      index_key = key.to_sym == :file ? 2 : 1
      returning([]) do |info|
        send_cmd "show acl" do |line|
          # Format: 0 (./acl_path.lst) pattern loaded from file './acl_path.lst' used by acl at file 'test-hap.cfg' line 32
          data = /([0-9]+) \((.*)\) (.*)/.match(line)
          if data
            key, value = line.split(': ')
            info << {id: data[1], file: data[2], description: data[3]}
          end
        end
      end
    end

    def add_acl_value(acl, value)
      id = normalize_acl_name(acl)
      rv = nil
      lines = 0
      send_cmd "add acl #{id} #{value}" do |line|
        rv = line
        lines +=1
      end
      rule = get_acl_value(acl, value)
      raise("Update failed") if (rule["match"] != 'yes')
      rule
    end

    #verify line number == 1
    def del_acl_value(acl, value)
      id = normalize_acl_name(acl)
      rv = nil
      lines = 0
      send_cmd "del acl #{id} #{value}" do |line|
        rv = line
        lines +=1
      end
      rule = get_acl_value(acl, value)
      raise("Update failed") if (!['Done.', 'Key not found.'].include? 'Done.') || (rule["match"] == 'yes')
      rule
    end

    def show_acl(acl)
      id = normalize_acl_name(acl)
      returning([]) do |info|
        send_cmd "show acl #{id}" do |line|
          d = line.split(" ")
          info << {d.first => d.last}
        end
      end
    end

    #verify line numbers should be == 1
    def get_acl_value(acl, value)
      id = normalize_acl_name(acl)
      returning({}) do |info|
        send_cmd "get acl #{id} #{value}" do |line|
          values = line.split(", ")
          values.each do |v|
            x = v.split("=")
            info[x.first] = x.last.gsub('"', "")
          end
        end
      end
    end

    def save_acl_rules(acl)
      id = normalize_acl_name(acl)
      acls = show_acls.select{|v| v[:id] == acl.to_s || v[:file] == acl.to_s}
      acls = acls.reject{|v| v[:file] == ""}
      raise("Please provide ACL tied to a file") if acls.empty?

      acl_rules = show_acl(acl).map{|v| v.values}.join("\n")
      acls.each do |acl|
        File.open(acl[:file], 'w') {|file| file.write acl_rules}
      end
    end

    def clear_acl(acl)
      id = normalize_acl_name(acl)
      rv = nil
      lines = 0
      send_cmd "clear acl #{id}" do |line|
        rv = line
        lines +=1
      end
      rules = show_acl(acl)
      puts rules
      raise("Update failed") if (rv != 'Done.') || (!rules.empty?)
      rules
    end


    def normalize_acl_name(acl)
      acl =~ /[0-9]+/ || acl.is_a?(Numeric) ? "##{acl}" : acl
    end


    #echo "show acl /etc/haproxy/slow_lane.lst" | sudo socat unix:/var/run/haproxy_stats.sock -
    #echo "del acl /etc/haproxy/slow_lane.lst 10.10.10.1" | sudo socat unix:/var/run/haproxy_stats.sock -
    #echo "add acl /etc/haproxy/slow_lane.lst 10.10.10.1" | sudo socat unix:/var/run/haproxy_stats.sock -
    #echo "show acl" | sudo socat unix:/var/run/haproxy_stats.sock -


  end
end