require 'spec_helper'
require 'htauth/digest_file'
require 'tempfile'

describe HTAuth::DigestFile do

    before(:each) do
        @tf             = Tempfile.new("rpasswrd-digest")
        @tf.write(IO.read(DIGEST_ORIGINAL_TEST_FILE))
        @tf.close       
        @digest_file    = HTAuth::DigestFile.new(@tf.path)
        
        @tf2                = Tempfile.new("rpasswrd-digest-empty")
        @tf2.close
        @empty_digest_file  = HTAuth::DigestFile.new(@tf2.path)
    end

    after(:each) do
        @tf2.close(true)
        @tf.close(true)
    end

    it "can add a new entry to an already existing digest file" do
        @digest_file.add_or_update("charlie", "htauth-new", "c secret")
        @digest_file.contents.should == IO.read(DIGEST_ADD_TEST_FILE)
    end

    it "can tell if an entry already exists in the digest file" do
        @digest_file.has_entry?("alice", "htauth").should == true
        @digest_file.has_entry?("alice", "some other realm").should == false
    end
    
    it "can update an entry in an already existing digest file" do
        @digest_file.add_or_update("alice", "htauth", "a new secret")
        @digest_file.contents.should == IO.read(DIGEST_UPDATE_TEST_FILE)
    end

    it "fetches a copy of an entry" do
        @digest_file.fetch("alice", "htauth").to_s.should == "alice:htauth:2f361db93147d84831eb34f19d05bfbb"
    end

    it "raises an error if an attempt is made to alter a non-existenet file" do
        lambda { HTAuth::DigestFile.new("some-file") }.should raise_error(HTAuth::FileAccessError)
    end

    # this test will only work on systems that have /etc/ssh_host_rsa_key 
    it "raises an error if an attempt is made to open a file where no permissions are granted" do
        lambda { HTAuth::DigestFile.new("/etc/ssh_host_rsa_key") }.should raise_error(HTAuth::FileAccessError)
    end

    it "deletes an entry" do
        @digest_file.delete("alice", "htauth")
        @digest_file.contents.should == IO.read(DIGEST_DELETE_TEST_FILE)
    end
    
    it "is usable in a ruby manner and yeilds itself when opened" do
        HTAuth::DigestFile.open(@tf.path) do |pf|
            pf.add_or_update("alice", "htauth", "a secret")
            pf.delete('bob', 'htauth')
        end
        lines = IO.readlines(@tf.path)
        lines.size.should == 1
        lines.first.strip.should == "alice:htauth:2f361db93147d84831eb34f19d05bfbb"
    end
end
