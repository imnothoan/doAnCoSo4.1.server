const { supabase } = require('./db/supabaseClient')

async function test() {
  console.log('Checking connection Supabase...')

  const { data, error } = await supabase.from('users').select('id').limit(1)

  if (error) {
    console.error('Error:', error.message)
  } else {
    console.log('Success:', data)
  }
}

test()
