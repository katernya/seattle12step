package S12S;

           use MongoDBI;

           app {

               # shared mongodb connection
               database => {
                   name => 'mongodbi_s12s',
                   host => 'mongodb://localhost:27017'
               },

               # load child doc classes
               classes => {
                   self => 1, # loads CDDB::*
                   load => ['S12S::Meeting']
               }

           };
1;
