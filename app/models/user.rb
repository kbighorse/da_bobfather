class User < ActiveRecord::Base
  attr_accessible :email, :node_id, :favorite_donut, :fb_access_token, :fbid, :is_bobfather, :last_login, :name, :registered, :state
  # for posting children
  attr_accessible :bobchildren, :bobfather
  
  # i essentially have my own methods for handling the logic for bobchildren
  attr_accessor :bobchildren # http://www.ruby-forum.com/topic/1748016
  
  
  after_create :create_neo
  after_update :update_neo
  before_destroy :destroy_neo

  # States of Bobfatherhood
  UNKNOWN_BOBFATHER = '0'
  I_AM_BOBFATHER = '-1'
  FEATUREALBE = "featurable"
  ## States of Relationship.  
  PROPOSED_BY_FATHER = 'proposed_by_father'
  PROPOSED_BY_CHILD = 'proposed_by_child'
  CONFIRMED = 'confirmed'
  # Relationships
  FRIENDS_REL = "friends"
  BOBFATHER_REL = "bobfather"

  LARGE_NUMBER = 10 # the "all" depth option isn't supported in many places

  def neo_con
    if $neo 
     return $neo
    else
      $neo = Neography::Rest.new
      Rails.logger.info("Neography Bug Connection Got Dropped")
    end 
  end 
  
  ##############################################################################
  # neo4J connection/access node methods
  ##############################################################################
  def neo_node_id(node)
    node_id = node["self"].split('/').last
  end
  
  def neo_end_node_id(relationship)
    node_id = relationship["end"].split('/').last
  end

  def neo_start_node_id(relationship)
    node_id = relationship["start"].split('/').last
  end
  
  def my_node
    neo_con.get_node(self.node_id)
  end
  
  def get_start_node(relationship)
    User.find_by_node_id( neo_start_node_id(relationship) )
  end

  def get_end_node(relationship)
    User.find_by_node_id( neo_end_node_id(relationship) )
  end
  
  
  ##############################################################################
  # neo4J hook mehtods
  ##############################################################################

  def create_neo    
    node = neo_con.create_node(self.attribute_names.collect {|x| [x,  self.send(x)]}.inject({}) { |r, s| r.merge!({s[0] => s[1]} ) } )
    # puts node
    # map the graph db back to the model
    my_node_id = self.neo_node_id(node)
    puts "My nodeid::#{my_node_id}"
    self.update_attributes({:node_id => my_node_id})
  end
  
  # @neo.reset_node_properties(node1, {"age" => 31})           # Reset a node's properties
  # @neo.set_node_properties(node1, {"weight" => 200})         # Set a node's properties
  def update_neo
    node = neo_con.get_node(self.node_id)
    # i'll store meta data in active record
    # updated_attr = self.attribute_names.collect {|x| [x,  self.send(x)]}.inject({}) { |r, s| r.merge!({s[0] => s[1]} ) }
    # updated_attr = updated_attr.delete_if {|k, v| v.nil?}
    # neo_con.set_node_properties(node,  updated_attr)
  end
  
  
  # @neo.delete_node(node2) # Delete an unrelated node
  # @neo.delete_node!(node2) # Delete a node and all its relationships
  def destroy_neo
    begin
      node = neo_con.get_node(self.node_id)
      neo_con.delete_node!(node)
    rescue => e
      puts e
    end
  end
  
  ##############################################################################
  # neo4J Core association methods  getters and setters
  ##############################################################################

  # Bobfather and Bobchildren

  # return nil or a User object
  def bobfather
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", BOBFATHER_REL)
    return nil if !array_of_hashes
    raise "Can't have mulitple Bobfathers" if array_of_hashes.size > 1
    User.find_by_node_id( neo_end_node_id(array_of_hashes.first) )
  end

  # pass in either an object or id.  helpful for rails style forms
  def bobfather=(user_or_user_id)
    if user_or_user_id.class == String
      # state machine logic in here for UNKNOWN Bobfther or OUT OF NETWORK Bobfather
      self.update_bobfather(user_or_user_id)
    else
      set_bobfather(user_or_user_id)
    end  
  end
  
  def set_bobfather(user)
    # destroying old bobfather relation in neo4j to preserve uniqueness
    if self.has_bobfather?
      self.bobfather_rel_destroy
    end    
    neo_con.create_relationship(BOBFATHER_REL, self.my_node, user.my_node)
  end

  def update_bobfather(bobfather_id)
    if bobfather_id == UNKNOWN_BOBFATHER
      Rails.logger.info("User has An Out of Network Bobfather")
      # if there is a bobfather rel created
      if self.has_bobfather?
        array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", BOBFATHER_REL)
        relationid =  neo_node_id(array_of_hashes.first)
        neo_con.delete_relationship(relationid) # will this work?
      end
    elsif bobfather_id == I_AM_BOBFATHER
      if self.has_bobfather?
        array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", BOBFATHER_REL)
        relationid =  neo_node_id(array_of_hashes.first)
        neo_con.delete_relationship(relationid) # will this work?
      end
    elsif !bobfather_id.blank?
      u = User.find(bobfather_id)
      set_bobfather(u)
      # do state machine
      # @neo.set_relationship_properties(rel1, {"weight" => 200}) 
      # @neo.get_relationship_properties(rel1)        
      if self.has_bobfather_state? and self.bobfather_state == PROPOSED_BY_FATHER
        self.bobfather_state = CONFIRMED
      else
        self.bobfather_state = PROPOSED_BY_CHILD
      end
      save
    else
      Rails.logger.info("User has no Bobfather")
    end
  end


  # should return a relationship object/hash object
  def bobfather_rel
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", BOBFATHER_REL)
    puts "bobfather_rel : #{array_of_hashes.first}"
    array_of_hashes.first
  end
  
  # neo_con.delete_relationship(relationid) # will this work?
  def bobfather_rel_destroy
    puts "\nabout to destory the Bobfather relationship of #{self.name}\n"
    neo_con.delete_relationship(self.bobfather_rel) # will this work?
  end


  def bobchildren
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "in", BOBFATHER_REL)
    return [] if !array_of_hashes
    # Rails.logger.info("bobchildren ids::#{array_of_hashes.collect{ |x| neo_node_id(x) }}")
    User.where(:node_id => array_of_hashes.collect{ |x| neo_start_node_id(x) } )
  end

  # business logic of who gets to delete what can go here
  def update_bobchildren(bobchildren_ids)
    bobchildren_ids.reject! {|x| x.empty? }
    
    remove_bobchild_relationships(bobchildren_ids)
    # add the newly checked children
    add_bobchild_reationships(bobchildren_ids)
  end


  # remove the Unchecked Checkboxes
  def remove_bobchild_relationships(bobchildren_ids)
    existing_bobchildren_ids = bobchildren.collect {|x| x.id}
    delete_child_relaitonships = existing_bobchildren_ids - bobchildren_ids
    Rails.logger.info("\nexisting_bobchildren::#{existing_bobchildren_ids}\n")
    Rails.logger.info("\ndelete_child_relaitonships::#{delete_child_relaitonships}\n")

    delete_child_relaitonships.each do |uid|
      u = User.find(uid)
      # my new method
      u.bobfather_rel_destroy
      # u.bobfather_rel.destroy
    end
  end
  
  # State Machine Logic Applies here
  ## TOOD Refactor somewhere nice
  def add_bobchild_reationships(bobchildren_ids)
    Rails.logger.info("\n\nadding bobchildren:#{bobchildren_ids}\n\n")
    bobchildren_ids.each do |child_id|
      u = User.find(child_id)
      if u.has_bobfather?
        Rails.logger.info("\n this user has a bobfather")
        # This is A CONFIRMATION of the bobfatherhood 
        if ( (u.bobfather == self) and 
              (u.has_bobfather_state? and u.bobfather_state == PROPOSED_BY_CHILD) )
          u.bobfather_state = CONFIRMED
        end
        # if u.bobfather != self DO NOTHING b/c da child has ownship of 
        #  WHO IS MY BOBFATHER      
      else
        Rails.logger.info("\n Adding the bobfather rel")
        u.bobfather = self 
        # do state machine
        u.bobfather_state = PROPOSED_BY_FATHER
      end
      u.save
    end
  end

  # what does this return
  def bobfather_state
    neo_con.get_relationship_properties(self.bobfather_rel, ['state'])
  end

  def bobfather_state=(status)
  end
  
  

  # Friends 
  
  # make this more active record like
  def friends
    return [] if !has_friends?
    # and array of friend relationships NOT actual nodes
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", FRIENDS_REL)
    # objects = array_of_hashes.map{|m| OpenStruct.new(m)}
    # even better, just get the full user objects
    # puts "array_of_hashes.collect{|x| x['data'']['id']}::#{array_of_hashes.collect{|x| x['data']['id']}} "
    # puts "array_of_hashes.collect{ |x| neo_node_id(x) }::#{array_of_hashes.collect{ |x| neo_node_id(x) }} "

    User.where(:node_id => array_of_hashes.collect{ |x| neo_end_node_id(x) })
  end

  # @neo.create_relationship("friends", node1, node2)          # Create a relationship between node1 and node2
  # @neo.create_unique_relationship(index_name, key, value,    # Create a unique relationship between nodes
  #                           "friends", new_node1, new_node2)   # this needs an existing index
  def add_to_friends(user)
    neo_con.create_relationship(FRIENDS_REL, self.my_node, user.my_node)
  end

  def friend_ids
    return [] if !has_friends?
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", FRIENDS_REL)
    User.select(:id).where(:node_id => array_of_hashes.collect{ |x| neo_end_node_id(x) })
  end


  ##############################################################################
  # ? methods
  ##############################################################################
  # ex. @neo.get_node_relationships(node1, "all", "enemies")
  def has_friends?
    !!neo_con.get_node_relationships(self.my_node, "out", FRIENDS_REL) # returns nil if empty
  end


  def has_bobfather?
    self.bobfather ? true : false
  end
  
  def has_bobchildren?
    !!neo_con.get_node_relationships(self.my_node, "in", BOBFATHER_REL)
  end

  def has_bobfather_state?
    rel1 = neo_con.get_relationship_properties(self.bobfather_rel)
    if rel1 and rel1['state']
      return true
    end
    false
  end

  ##############################################################################
  # Traversal methods
  ##############################################################################
  

  # nodes = @neo.traverse(node1,                            # the node where the traversal starts
  #     "nodes",                                            # return_type "nodes", "relationships" or "paths"
  #     {"order" => "breadth first",                        # "breadth first" or "depth first" traversal order
  #      "uniqueness" => "node global",                     # See Uniqueness in API documentation for options.
  #      "relationships" => [{"type"=> "roommates",         # A hash containg a description of the traversal
  #                           "direction" => "all"},        # two relationships.
  #                          {"type"=> "friends",           #
  #                           "direction" => "out"}],       #
  #      "prune evaluator" => {"language" => "javascript",  # A prune evaluator (when to stop traversing)
  #                            "body" => "position.endNode().getProperty('age') < 21;"},
  #      "return filter" => {"language" => "builtin",       # "all" or "all but start node"
  #                          "name" => "all"},
  #      "depth" => 4})

  def lineage_total
    nodes = neo_con.traverse(self.my_node,
      "nodes",
      {"uniqueness" => "node global",
        "relationships" => [{"type"=> BOBFATHER_REL, # A hash containg a description of the traversal
                             "direction" => "in"}],
      "depth" => LARGE_NUMBER})
    #self.incoming(:bobfather).depth(:all).count
    # puts nodes
    return nodes.size
  end

  def relation(user)
    # traversal = self.both(:bobfather).depth(:all).unique(:node_path).eval_paths { |path|  (path.end_node[:fbid] == user[:fbid]) ? :include_and_continue : :exclude_and_continue }
    path = neo_con.get_path(self.my_node, user.my_node, [{"type" => BOBFATHER_REL, "direction" => "all"}], depth=10, algorithm="shortestPath") 
    Rails.logger.info("\n\np#{path.class}#{path}\n") 
    path
    # i want the relations from the path
    path["relationships"].collect {|rel1| neo_con.get_relationship(rel1)}
  end
  
  
  # NOTE.  the API is weird.  raises an error if it can't find a relation
  def related?(user)
    # finds the shortest path between two nodes
    
    # note!  Depth all doesn't seem to work, So i'll set to high number instead??
    begin
      path = neo_con.get_path(self.my_node, user.my_node, [{"type" => BOBFATHER_REL, "direction" => "all"}], depth=10, algorithm="shortestPath") 
      return true if path
    rescue => e
      Rails.logger.info("The related path error:#{e}")
      return false
    end
    false
  end
  
  
  # who is the bobfather at the top of the lineage
  def don_bobfather
    #traversal = self.outgoing(:bobfather).depth(:all).to_a.last #.   #filter{|path| path.end_node.has_bobfather?}.
    nodes = neo_con.traverse(self.my_node,
        "nodes",
        {"uniqueness" => "node global",
          "relationships" => [{"type"=> BOBFATHER_REL, # A hash containg a description of the traversal
                               "direction" => "out"}],
        "depth" => LARGE_NUMBER})
      #self.incoming(:bobfather).depth(:all).count
      # puts nodes
    return false if !nodes.last 
    User.find_by_node_id(neo_node_id(nodes.last))
  end

  ##############################################################################
  # end neo4J methods
  ##############################################################################


  ##############################################################################
  # third party mehtods
  ##############################################################################

  def get_fb_friends    
    fb_user = FbGraph::User.me(self.fb_access_token)
    my_friends = fb_user.friends
    friend_ids_list = self.friend_ids
    my_friends.each do |f|
      # puts("f.identifier::#{f.identifier} pre search")
      u = User.find_by_fbid(f.identifier)
      if !u
        puts("f.identifier::#{f.identifier} not found, creating a friend and node")
        u = User.create(:fbid => f.identifier)
      else
        # puts an old friend
      end
      u.name = f.name if !u.name
      u.save # has to be here to persist friends name
      if friend_ids_list.include?(u.id)
        puts "already a friend #{u.name}"
      else
        puts "adding a friend #{u.name}"
        self.add_to_friends(u)
        # keep track in an array so i don't do 5K queries and timeout
        friend_ids_list << u.id
      end
      
    end
    save
  end
  



  ##############################################################################
  # Non Neo4j Mehtods
  ##############################################################################
  # update this at some point to 
  def bobfather_status
    plug = ''
    plug = ".  Invite them to sign up" if not registered?
    return "#{self.name } is the bobfather#{plug}"
  end
  
  def update_from_fb_omniuath(auth)
    uinfo = auth['info'] # with changes to the user info hash from authentication with facebook    
    raise "Missing user info in auth" if uinfo.nil?    
    # raise "Missing auth" if auth.nil?
    # Rails.logger.info("\n\nFacebook User::#{auth.inspect}\n\n#{uinfo.inspect}")
    self.fb_access_token = auth['credentials']['token']
    self.email = uinfo['email']
    self.name = uinfo['name']
  end

  # og protocal, not request needed
  def fb_image_url(size = nil)
    url = "http://graph.facebook.com/#{self.fbid}/picture"
    url = "#{url.split('?')[0]}?type=large" if size
    url
  end

  def registered?
    registered
  end

  def is_bobfather?
    is_bobfather
  end
  
  def new_registration?
    !registered?
  end

  ##############################################################################
  # Class Methods
  ##############################################################################


  def User.kill_all
    User.all.each {|x| x.destroy}
    # gremlin script to kill all nodes
    @neo = Neography::Rest.new
    @neo.execute_script("g.clear()")
  end  

  def User.neo_count
    @neo = Neography::Rest.new
    gremlin_output = @neo.execute_query("start n = node(*) return count(n)")
    puts gremlin_output
    gremlin_output['data'].first.first
  end

  ##############################################################################
  # neo4J debugging methods to see what neo looks like under the hood
  ##############################################################################
  def neo_friends
    return [] if !has_friends?
    # and array of friend nodes
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", FRIENDS_REL)
    # objects = array_of_hashes.map{|m| OpenStruct.new(m)}
  end

  def neo_friends_relationship
    return [] if !has_friends?
    # and array of friend nodes
    array_of_hashes = neo_con.get_node_relationships(self.my_node, "out", FRIENDS_REL)
    objects = array_of_hashes.map{|m| OpenStruct.new(m)}
  end
  


  # What I'm porting from neo4j Gem
  ##############################################################################
  # neo4J associations
  ##############################################################################
  
  # has_one(:bobfather)
  # has_n(:friends)
  
  ##############################################################################
  # rails style associations
  ##############################################################################
  # add this back in later.  do it all in graph library now
  # has_ancestry # this is the bobfather relation for ActiveRecord


end
